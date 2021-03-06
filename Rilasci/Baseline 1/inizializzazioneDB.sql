/* Script SQL di inizializzazione del database dell'applicazione Sistema Editoriale
	Gruppo Azzurro, UIIP Maggio 2013
*/

/* Viene creato l'utente GRUPPO_AZZURRO con la password GRUPPO_AZZURRO
	e gli vengono assegnati tutti i privilegi per poter utilizzare il database
*/
CREATE USER GRUPPO_AZZURRO IDENTIFIED BY GRUPPO_AZZURRO;
GRANT ALL PRIVILEGES TO GRUPPO_AZZURRO;

/* Viene creata una funzione chiamata MD5 che utilizza l'omonimo algoritmo 
	per crittografare le password all'interno del database
*/
create or replace
FUNCTION MD5 (
    CADENA IN VARCHAR2
) RETURN DBMS_OBFUSCATION_TOOLKIT.VARCHAR2_CHECKSUM
AS
BEGIN
      RETURN LOWER(
        RAWTOHEX(
            UTL_RAW.CAST_TO_RAW(
                DBMS_OBFUSCATION_TOOLKIT.MD5(INPUT_STRING => CADENA)
            )
        )
      );
END;
/

/* Viene creata una sequenza per gestire gli ID associati alla tabella NOTIZIA
*/
CREATE SEQUENCE "GRUPPO_AZZURRO"."NOTIZIA_SEQUENCE" 
	MINVALUE 0
	MAXVALUE 9999999999999999999999999999
    START WITH 0
    INCREMENT BY 1
    CACHE 20;

/* Viene creata la tabella ACCOUNT
*/
CREATE TABLE "GRUPPO_AZZURRO"."ACCOUNT"
  (
    "NOME"              VARCHAR2(55 BYTE) NOT NULL ENABLE,
    "COGNOME"           VARCHAR2(55 BYTE) NOT NULL ENABLE,
    "USERNAME"          VARCHAR2(20 BYTE) NOT NULL ENABLE,
    "PASSWORD"          VARCHAR2(32 BYTE) NOT NULL ENABLE,
    "SIGLA_REDAZIONE"   VARCHAR2(40 BYTE),
    "SIGLA_GIORNALISTA" VARCHAR2(40 BYTE),
    "STATO"             VARCHAR2(1 BYTE) DEFAULT 'A' NOT NULL ENABLE,
    CONSTRAINT "ACCOUNT_PK" PRIMARY KEY ("USERNAME") USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645 PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT) TABLESPACE "USERS" ENABLE,
    CONSTRAINT "ACCOUNT_UK1" UNIQUE ("SIGLA_GIORNALISTA") USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645 PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT) TABLESPACE "USERS" ENABLE
  )
  SEGMENT CREATION IMMEDIATE PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING STORAGE
  (
    INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645 PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT
  )
  TABLESPACE "USERS" ;

/* Viene creata la tabella NOTIZIA
*/
CREATE TABLE "GRUPPO_AZZURRO"."NOTIZIA"
  (
    "STATO"             VARCHAR2(1 BYTE) DEFAULT 'S' NOT NULL ENABLE,
    "BLOCCO"            VARCHAR2(1 BYTE) DEFAULT 'N',
    "TITOLO"            VARCHAR2(255 BYTE) NOT NULL ENABLE,
    "SOTTOTITOLO"       VARCHAR2(255 BYTE) NOT NULL ENABLE,
    "AUTORE"            VARCHAR2(40 BYTE) NOT NULL ENABLE,
    "ULTIMO_DIGITATORE" VARCHAR2(40 BYTE) DEFAULT NULL,
    "TESTO" CLOB NOT NULL ENABLE,
    "LUNGHEZZA_TESTO" NUMBER(*,0) NOT NULL ENABLE,
    "DATA_CREAZIONE" TIMESTAMP (6) NOT NULL ENABLE,
    "DATA_TRASMISSIONE" TIMESTAMP (6),
    "ID" NUMBER NOT NULL ENABLE,
    CONSTRAINT "NOTIZIA_CHK1" CHECK (STATO  = 'S'
  OR STATO                                  = 'Q'
  OR STATO                                  = 'T'
  OR STATO                                  = 'C') ENABLE,
    CONSTRAINT "NOTIZIA_CHK2" CHECK (BLOCCO = 'Y'
  OR BLOCCO                                 = 'N') ENABLE,
    CONSTRAINT "NOTIZIA_PK" PRIMARY KEY ("ID") USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645 PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT) TABLESPACE "USERS" ENABLE,
    CONSTRAINT "NOTIZIA_ACCOUNT_FK1" FOREIGN KEY ("ULTIMO_DIGITATORE") REFERENCES "GRUPPO_AZZURRO"."ACCOUNT" ("USERNAME") ON
  DELETE
    SET NULL ENABLE
  )
  SEGMENT CREATION IMMEDIATE PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING STORAGE
  (
    INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645 PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT
  )
  TABLESPACE "USERS" LOB
  (
    "TESTO"
  )
  STORE AS BASICFILE
  (
    TABLESPACE "USERS" ENABLE STORAGE IN ROW CHUNK 8192 RETENTION NOCACHE LOGGING STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645 PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  ) ;

/* Viene creato un trigger per settare, se non esplicitamente indicato, l'ID
	della notizia che si sta inserendo
*/
CREATE OR REPLACE TRIGGER "GRUPPO_AZZURRO"."NOTIZIA_TRIGGER"
  BEFORE INSERT ON "GRUPPO_AZZURRO"."NOTIZIA" 
  FOR EACH ROW 
	BEGIN 
		IF :NEW.ID IS NULL THEN
			SELECT NOTIZIA_SEQUENCE.nextval INTO :NEW.ID FROM dual;
		END IF;
	END;
/

ALTER TRIGGER "GRUPPO_AZZURRO"."NOTIZIA_TRIGGER" ENABLE;

/* Viene creato il trigger NOTIZIA_AUTORE_TRIGGER che controlla se l'autore della notizia che si sta inserendo o modificando
	sia un fornitore esterno (autore RCV) oppure se sia un account interno dell'applicazione
*/
CREATE OR REPLACE TRIGGER "GRUPPO_AZZURRO"."NOTIZIA_AUTORE_TRIGGER"
  BEFORE INSERT OR UPDATE OF AUTORE ON "GRUPPO_AZZURRO"."NOTIZIA" 
  FOR EACH ROW
	DECLARE contatore NUMBER;
	BEGIN
		SELECT count(*) INTO contatore FROM ACCOUNT WHERE USERNAME = :new.AUTORE;
		IF
			:new.autore != 'RCV' and contatore != 1
		THEN
			raise_application_error(-20001, 'Autore non valido.');
		END IF;
	END;
/

/* Viene creata la tabella GRUPPO
*/
CREATE TABLE "GRUPPO_AZZURRO"."GRUPPO"
  (
    "NOME_GRUPPO" VARCHAR2(40 BYTE) NOT NULL ENABLE,
    "DESCRIZIONE" VARCHAR2(255 BYTE),
    CONSTRAINT "GRUPPO_PK" PRIMARY KEY ("NOME_GRUPPO") USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645 PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT) TABLESPACE "USERS" ENABLE
  )
  SEGMENT CREATION IMMEDIATE PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING STORAGE
  (
    INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645 PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT
  )
  TABLESPACE "USERS" ;

/* Viene creata la tabella FUNZIONALITA
*/
CREATE TABLE "GRUPPO_AZZURRO"."FUNZIONALITA"
  (
    "SIGLA_FUNZIONALITA" VARCHAR2(40 BYTE) NOT NULL ENABLE,
    "NOME_FUNZIONALITA"  VARCHAR2(55 BYTE),
    CONSTRAINT "FUNZIONALITA_PK" PRIMARY KEY ("SIGLA_FUNZIONALITA") USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 NOCOMPRESS LOGGING TABLESPACE "USERS" ENABLE
  )
  SEGMENT CREATION DEFERRED PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING TABLESPACE "USERS" ;

/* Viene creata la tabella ACCOUNT_GRUPPO di associazione tra gli account e i gruppi di appartenenza
*/
CREATE TABLE "GRUPPO_AZZURRO"."ACCOUNT_GRUPPO"
  (
    "USERNAME"    VARCHAR2(55 BYTE) NOT NULL ENABLE,
    "NOME_GRUPPO" VARCHAR2(40 BYTE) NOT NULL ENABLE,
    CONSTRAINT "ACCOUNT_GRUPPO_PK" PRIMARY KEY ("USERNAME", "NOME_GRUPPO") USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 NOCOMPRESS LOGGING TABLESPACE "USERS" ENABLE,
    CONSTRAINT "ACCOUNT_GRUPPO_GRUPPO_FK1" FOREIGN KEY ("NOME_GRUPPO") REFERENCES "GRUPPO_AZZURRO"."GRUPPO" ("NOME_GRUPPO") ON
  DELETE CASCADE ENABLE,
    CONSTRAINT "ACCOUNT_GRUPPO_ACCOUNT_FK1" FOREIGN KEY ("USERNAME") REFERENCES "GRUPPO_AZZURRO"."ACCOUNT" ("USERNAME") ON
  DELETE CASCADE ENABLE
  )
  SEGMENT CREATION DEFERRED PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING TABLESPACE "USERS" ;

/* Viene creata la tabella GRUPPO_FUNZIONALITA di associazione tra i gruppi e le funzionalitą che possiedono
*/
CREATE TABLE "GRUPPO_AZZURRO"."GRUPPO_FUNZIONALITA"
  (
    "NOME_GRUPPO"        VARCHAR2(40 BYTE) NOT NULL ENABLE,
    "SIGLA_FUNZIONALITA" VARCHAR2(40 BYTE) NOT NULL ENABLE,
    CONSTRAINT "GRUPPO_FUNZIONALITA_PK" PRIMARY KEY ("NOME_GRUPPO", "SIGLA_FUNZIONALITA") USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 NOCOMPRESS LOGGING TABLESPACE "USERS" ENABLE,
    CONSTRAINT "GRUPPO_FUNZIONALITA_FUNZI_FK1" FOREIGN KEY ("SIGLA_FUNZIONALITA") REFERENCES "GRUPPO_AZZURRO"."FUNZIONALITA" ("SIGLA_FUNZIONALITA") ON
  DELETE CASCADE ENABLE,
    CONSTRAINT "GRUPPO_FUNZIONALITA_GRUPP_FK1" FOREIGN KEY ("NOME_GRUPPO") REFERENCES "GRUPPO_AZZURRO"."GRUPPO" ("NOME_GRUPPO") ON
  DELETE CASCADE ENABLE
  )
  SEGMENT CREATION DEFERRED PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING TABLESPACE "USERS" ;
  
/* Vengono eseguiti gli inserimenti iniziali per inizializzare il database e renderlo subito accessibile ed utilizzabile
*/
INSERT INTO "GRUPPO_AZZURRO"."GRUPPO" (NOME_GRUPPO,DESCRIZIONE) VALUES('Amministratore','Rappresenta il gruppo di amministrazione del sistema');
INSERT INTO "GRUPPO_AZZURRO"."GRUPPO" (NOME_GRUPPO,DESCRIZIONE) VALUES('Giornalista','Rappresenta il gruppo di utenti che possono gestire le notizie');

INSERT INTO "GRUPPO_AZZURRO"."FUNZIONALITA" (SIGLA_FUNZIONALITA,NOME_FUNZIONALITA) VALUES ('CreaAcc','Crea Account');
INSERT INTO "GRUPPO_AZZURRO"."FUNZIONALITA" (SIGLA_FUNZIONALITA,NOME_FUNZIONALITA) VALUES ('CancAcc','Cancella Account');
INSERT INTO "GRUPPO_AZZURRO"."FUNZIONALITA" (SIGLA_FUNZIONALITA,NOME_FUNZIONALITA) VALUES ('ModAcc','Modifica Account');
INSERT INTO "GRUPPO_AZZURRO"."FUNZIONALITA" (SIGLA_FUNZIONALITA,NOME_FUNZIONALITA) VALUES ('ListAcc','Lista Account');
INSERT INTO "GRUPPO_AZZURRO"."FUNZIONALITA" (SIGLA_FUNZIONALITA,NOME_FUNZIONALITA) VALUES ('CreaNot','Crea Notizia');
INSERT INTO "GRUPPO_AZZURRO"."FUNZIONALITA" (SIGLA_FUNZIONALITA,NOME_FUNZIONALITA) VALUES ('ModNot','Modifica Notizia');
INSERT INTO "GRUPPO_AZZURRO"."FUNZIONALITA" (SIGLA_FUNZIONALITA,NOME_FUNZIONALITA) VALUES ('RegNot','Registra Notizia');
INSERT INTO "GRUPPO_AZZURRO"."FUNZIONALITA" (SIGLA_FUNZIONALITA,NOME_FUNZIONALITA) VALUES ('CancNot','Cancella Notizia');
INSERT INTO "GRUPPO_AZZURRO"."FUNZIONALITA" (SIGLA_FUNZIONALITA,NOME_FUNZIONALITA) VALUES ('TxNot','Trasmetti Notizia');
INSERT INTO "GRUPPO_AZZURRO"."FUNZIONALITA" (SIGLA_FUNZIONALITA,NOME_FUNZIONALITA) VALUES ('VisNot','Visualizza Notizia');
INSERT INTO "GRUPPO_AZZURRO"."FUNZIONALITA" (SIGLA_FUNZIONALITA,NOME_FUNZIONALITA) VALUES ('ListNot','Lista Notizie');
INSERT INTO "GRUPPO_AZZURRO"."FUNZIONALITA" (SIGLA_FUNZIONALITA,NOME_FUNZIONALITA) VALUES ('Ann','Annulla');

INSERT INTO "GRUPPO_AZZURRO"."ACCOUNT" (NOME,COGNOME,USERNAME,PASSWORD,SIGLA_REDAZIONE,SIGLA_GIORNALISTA) VALUES ('Amministratore','Amministratore','admin',MD5('admin'),'adm','adm');
INSERT INTO "GRUPPO_AZZURRO"."ACCOUNT" (NOME,COGNOME,USERNAME,PASSWORD,SIGLA_REDAZIONE,SIGLA_GIORNALISTA) VALUES ('Amministratore e Giornalista','Amministratore e Giornalista','admingio',MD5('admingio'),'admgio','admgio');
INSERT INTO "GRUPPO_AZZURRO"."ACCOUNT" (NOME,COGNOME,USERNAME,PASSWORD,SIGLA_REDAZIONE,SIGLA_GIORNALISTA) VALUES ('Giornalista Default','Giornalista Default','gio',MD5('gio'),'gio','gio');

INSERT INTO "GRUPPO_AZZURRO"."ACCOUNT_GRUPPO" (USERNAME,NOME_GRUPPO) VALUES ('admin','Amministratore');
INSERT INTO "GRUPPO_AZZURRO"."ACCOUNT_GRUPPO" (USERNAME,NOME_GRUPPO) VALUES ('gio','Giornalista');
INSERT INTO "GRUPPO_AZZURRO"."ACCOUNT_GRUPPO" (USERNAME,NOME_GRUPPO) VALUES ('admingio','Amministratore');
INSERT INTO "GRUPPO_AZZURRO"."ACCOUNT_GRUPPO" (USERNAME,NOME_GRUPPO) VALUES ('admingio','Giornalista');

INSERT INTO "GRUPPO_AZZURRO"."GRUPPO_FUNZIONALITA" (NOME_GRUPPO, SIGLA_FUNZIONALITA) VALUES ('Amministratore','CreaAcc');
INSERT INTO "GRUPPO_AZZURRO"."GRUPPO_FUNZIONALITA" (NOME_GRUPPO, SIGLA_FUNZIONALITA) VALUES ('Amministratore','CancAcc');
INSERT INTO "GRUPPO_AZZURRO"."GRUPPO_FUNZIONALITA" (NOME_GRUPPO, SIGLA_FUNZIONALITA) VALUES ('Amministratore','ModAcc');
INSERT INTO "GRUPPO_AZZURRO"."GRUPPO_FUNZIONALITA" (NOME_GRUPPO, SIGLA_FUNZIONALITA) VALUES ('Amministratore','ListAcc');
INSERT INTO "GRUPPO_AZZURRO"."GRUPPO_FUNZIONALITA" (NOME_GRUPPO, SIGLA_FUNZIONALITA) VALUES ('Giornalista','CreaNot');
INSERT INTO "GRUPPO_AZZURRO"."GRUPPO_FUNZIONALITA" (NOME_GRUPPO, SIGLA_FUNZIONALITA) VALUES ('Giornalista','ModNot');
INSERT INTO "GRUPPO_AZZURRO"."GRUPPO_FUNZIONALITA" (NOME_GRUPPO, SIGLA_FUNZIONALITA) VALUES ('Giornalista','RegNot');
INSERT INTO "GRUPPO_AZZURRO"."GRUPPO_FUNZIONALITA" (NOME_GRUPPO, SIGLA_FUNZIONALITA) VALUES ('Giornalista','CancNot');
INSERT INTO "GRUPPO_AZZURRO"."GRUPPO_FUNZIONALITA" (NOME_GRUPPO, SIGLA_FUNZIONALITA) VALUES ('Giornalista','TxNot');
INSERT INTO "GRUPPO_AZZURRO"."GRUPPO_FUNZIONALITA" (NOME_GRUPPO, SIGLA_FUNZIONALITA) VALUES ('Giornalista','VisNot');
INSERT INTO "GRUPPO_AZZURRO"."GRUPPO_FUNZIONALITA" (NOME_GRUPPO, SIGLA_FUNZIONALITA) VALUES ('Giornalista','ListNot');
INSERT INTO "GRUPPO_AZZURRO"."GRUPPO_FUNZIONALITA" (NOME_GRUPPO, SIGLA_FUNZIONALITA) VALUES ('Giornalista','Ann');

COMMIT;
