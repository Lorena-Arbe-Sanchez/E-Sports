/*Scripts de borrado y creación de los TRIGGERS*/
DROP TRIGGER CANTIDAD_EQUIPO;
DROP TRIGGER GENERAR_CALENDARIO;
DROP TRIGGER NOMODIFICAR_EQUIPO;
DROP TRIGGER NOMODIFICAR_JUGADOR;
DROP TRIGGER MAXSALARIO_EQUIPO;
DROP TRIGGER PUNTOS_TOTALES;

/*Controlar que no haya más de 6 ni menos de 2 jugadores en un equipo.*/
CREATE OR REPLACE TRIGGER CANTIDAD_EQUIPO
BEFORE INSERT OR UPDATE OR DELETE ON JUGADOR
FOR EACH ROW
DECLARE
    v_cantidad NUMBER;
    e_pocosjugadores EXCEPTION;
BEGIN
    SELECT COUNT(*) INTO v_cantidad
    FROM JUGADOR
    WHERE id_equipo = :new.id_equipo;
    
    IF v_cantidad >= 6 THEN
        RAISE_APPLICATION_ERROR('-20001','No puede haber mas de 6 jugadores');
    ELSIF v_cantidad <= 2 THEN
        RAISE e_pocosjugadores;
    END IF;
    
EXCEPTION
    WHEN e_pocosjugadores THEN
        DBMS_OUTPUT.PUT_LINE('No puede haber menos de 2 jugadores');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error al recuperar información.');
END CANTIDAD_EQUIPO;

/

/*Controlar que para poder generar el calendario de una competición
todos los equipos tienen que tener un mínimo de 2 jugadores.*/
CREATE OR REPLACE TRIGGER GENERAR_CALENDARIO
BEFORE INSERT ON JORNADA
FOR EACH ROW
DECLARE
    v_cantidad_min NUMBER;
    v_equipo_id EQUIPO.ID_EQUIPO%TYPE;
BEGIN
    
    FOR lista_equipos IN (SELECT id_equipo FROM EQUIPO)
    LOOP
        v_cantidad_min := 0;
        v_equipo_id := lista_equipos.id_equipo;
    
        SELECT COUNT(*) INTO v_cantidad_min
        FROM JUGADOR
        WHERE id_equipo = v_equipo_id;
        
        IF v_cantidad_min < 2 THEN
            RAISE_APPLICATION_ERROR('-20001','Hay menos de 2 jugadores');
        END IF;
    END LOOP;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No se han encontrado equipos');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error al recuperar información.');

END GENERAR_CALENDARIO;

/

/*Controlar que una vez generado el calendario de la competición, no se
pueden modificar los equipos.*/
CREATE OR REPLACE TRIGGER NOMODIFICAR_EQUIPO
BEFORE UPDATE ON EQUIPO
FOR EACH ROW
DECLARE
    v_etapa_competicion COMPETICION.ETAPA%TYPE;
    e_etapa_cerrada EXCEPTION;
BEGIN

    SELECT ETAPA INTO v_etapa_competicion
    FROM COMPETICION
    WHERE id_competicion =(SELECT id_competicion
                            FROM equipo_competicion
                            WHERE id_equipo = :NEW.id_equipo); 
    IF v_etapa_competicion = 'C' THEN
        RAISE e_etapa_cerrada;
    END IF;
EXCEPTION
    WHEN e_etapa_cerrada THEN
        DBMS_OUTPUT.PUT_LINE('La competicion ya está cerrada');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error al recuperar información.');
END NOMODIFICAR_EQUIPO;

/

/*Controlar que una vez generado el calendario de la competición, no se
pueden modificar los jugadores de cada equipo.*/
CREATE OR REPLACE TRIGGER NOMODIFICAR_JUGADOR
BEFORE UPDATE ON JUGADOR
FOR EACH ROW
DECLARE
    v_etapa_competicion COMPETICION.ETAPA%TYPE;
    e_etapa_cerrada EXCEPTION;
BEGIN

    SELECT ETAPA INTO v_etapa_competicion
    FROM COMPETICION
    WHERE id_competicion =(SELECT id_competicion
                            FROM equipo_competicion
                            WHERE id_equipo = :NEW.id_equipo);
    IF v_etapa_competicion = 'C' THEN
        RAISE e_etapa_cerrada;
    END IF;
EXCEPTION
    WHEN e_etapa_cerrada THEN
        DBMS_OUTPUT.PUT_LINE('La competicion ya está cerrada');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error al recuperar información.');
END NOMODIFICAR_JUGADOR;

/

/*Controlar que el salario total de los jugadores del equipo no podrá ser
superior a 200.000€ anuales*/
CREATE OR REPLACE TRIGGER MAXSALARIO_EQUIPO
BEFORE INSERT OR UPDATE ON JUGADOR
FOR EACH ROW
DECLARE
    v_salarioanual_total NUMBER;
BEGIN    
    SELECT SUM(SUELDO * 12) INTO v_salarioanual_total
    FROM JUGADOR
    WHERE id_equipo = :new.id_equipo;
            
    IF v_salarioanual_total > 200000 THEN
        RAISE_APPLICATION_ERROR('-20001','El salario del equipo es más
            de 200000');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error al recuperar información.');
END MAXSALARIO_EQUIPO;

/

CREATE OR REPLACE TRIGGER actualizar_resultados
AFTER INSERT ON ENFRENTAMIENTO
FOR EACH ROW
DECLARE
    v_equipo1 NUMBER(2);
    v_equipo2 NUMBER(2);
    v_resultado1 NUMBER(2);
    v_resultado2 NUMBER(2);
BEGIN
    -- Obtener los datos del enfrentamiento insertado
    v_equipo1 := :NEW.ID_EQUIPO1;
    v_equipo2 := :NEW.ID_EQUIPO2;
    v_resultado1 := :NEW.RESULTADO1;
    v_resultado2 := :NEW.RESULTADO2;
    
    -- Actualizar los puntos del equipo 1 y 2 sumando el resultado obtenido
    UPDATE EQUIPO_COMPETICION
    SET PUNTOS = PUNTOS + v_resultado1
    WHERE ID_EQUIPO IN (v_equipo1, v_equipo2);

    -- Si el equipo 1 ganó, se le suma una victoria
    IF v_resultado1 > v_resultado2 THEN
        UPDATE EQUIPO_COMPETICION
        SET VICTORIAS = VICTORIAS + 1
        WHERE ID_EQUIPO = v_equipo1;
    -- Si el equipo 2 ganó, se le suma una victoria
    ELSIF v_resultado1 < v_resultado2 THEN
        UPDATE EQUIPO_COMPETICION
        SET VICTORIAS = VICTORIAS + 1
        WHERE ID_EQUIPO = v_equipo2;
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error al recuperar información.');
END;
