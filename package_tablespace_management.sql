

--
-- Registra os Logs sobre gerenciamento de tablespace
-- Records logs regarding tablespace management.


--
--
--
-- Sequence usada pela tabela LOG_SISTEMA
-- Sequence used by the LOG_SISTEMA table.
CREATE SEQUENCE SEQ_PK_INFO_LOG_GESTAO_TS INCREMENT BY 1 START WITH 1;


--
--
--
-- Armazena os logs gerados pelo sistema
-- Stores the logs generated by the system.
CREATE TABLE INFO_LOG_GESTAO_EXPANSAO_TS
(
  ID NUMBER(11) DEFAULT SEQ_PK_INFO_LOG_GESTAO_TS.NEXTVAL NOT NULL
, DATA_REGISTRO DATE DEFAULT SYSDATE NOT NULL
, MSG_LOG VARCHAR2(4000)
, CONSTRAINT cons_INFO_LOG_GESTAO_TS_PK PRIMARY KEY 
  (
    ID 
  )
  ENABLE 
);








--
--
-- Responsável por realizar o gerenciamento e criação de novos datafiles para tablespaces que estão chegando a 100% de uso
CREATE OR REPLACE PACKAGE WDS_GESTAO_EXPANSAO_TABLESPACE AS
--
-- Responsável por realizar o gerenciamento e criação de novos datafiles para tablespaces que estão chegando a 100% de uso
-- Responsible for managing and creating new datafiles for tablespaces that are approaching 100% usage.
--
-- GRANTs - SYS
--
-- GRANT SELECT ON SYS.DBA_DATA_FILES TO WDS_MONITORAMENTO;
-- GRANT SELECT ON SYS.DBA_FREE_SPACE TO WDS_MONITORAMENTO;
-- GRANT SELECT ON SYS.V_$TEMP_SPACE_HEADER TO WDS_MONITORAMENTO;
-- GRANT SELECT ON SYS.V_$TEMP_EXTENT_POOL TO WDS_MONITORAMENTO;
-- GRANT SELECT ON SYS.GV_$PARAMETER TO WDS_MONITORAMENTO;
-- GRANT ALTER TABLESPACE TO WDS_MONITORAMENTO;
--
--
-- ATENÇÃO:
--
-- Necessário ter o DB_CREATE_FILE_DEST definido
-- Required to have DB_CREATE_FILE_DEST defined.
--
--
-- Modo de usar:
--
--/
---> Em ambiente de TESTE
---> In a TEST environment.
---> WDS_GESTAO_EXPANSAO_TABLESPACE.GERENCIAR( TRUE );
--
--
---> Em ambiente de PRODUÇÃO
---> In a PRODUCTION environment.
---> WDS_GESTAO_EXPANSAO_TABLESPACE.GERENCIAR( FALSE );
--\
--
-- Autor: Wesley David Santos
-- Skype: wesleydavidsantos		
-- https://www.linkedin.com/in/wesleydavidsantos
--
	
	
	v_TAMANHO_MINIMO_DATAFILE CONSTANT VARCHAR2(20) := '500M';
	
	v_TAMANHO_MAXIMO_DATAFILE CONSTANT VARCHAR2(20) := '31G';
	
	
	PROCEDURE GERENCIAR( p_AMBIENTE_DE_TESTE BOOLEAN );
	
	
END WDS_GESTAO_EXPANSAO_TABLESPACE;
/


--
-- Realiza o cadastro de um novo cliente
CREATE OR REPLACE PACKAGE BODY WDS_GESTAO_EXPANSAO_TABLESPACE AS
--
-- Responsável por realizar o gerenciamento e criação de novos datafiles para tablespaces que estão chegando a 100% de uso
--
-- Autor: Wesley David Santos
-- Skype: wesleydavidsantos		
-- https://www.linkedin.com/in/wesleydavidsantos
--

	v_AMBIENTE_DE_TESTE BOOLEAN DEFAULT TRUE;


	PROCEDURE REGISTRAR_MSG_LOG( p_MSG VARCHAR2 ) AS
		
		RAISE_ERRO_OTHERS EXCEPTION;
		
	BEGIN
	
		BEGIN
		
			DBMS_OUTPUT.PUT_LINE( p_MSG );
			
		
			INSERT INTO INFO_LOG_GESTAO_EXPANSAO_TS ( MSG_LOG ) VALUES ( p_MSG );
			
			
			COMMIT;
			
		
		EXCEPTION
		
			WHEN OTHERS THEN
			
				DBMS_OUTPUT.PUT_LINE( 'ERRO -- Falha ao registrar uma mensagem na tabela de log de gerenciamento de tablespace.' );			
					
				RAISE RAISE_ERRO_OTHERS;
		
		END;
	
	
	END;
	
	
	
	PROCEDURE ADICIONAR_NOVO_DATAFILE( p_NOME_TABLESPACE VARCHAR2 ) AS
	
		v_STMT_DDL_CRIAR_DATAFILE VARCHAR2(4000) := 'ALTER TABLESPACE {NOME_TABLESPACE} ADD DATAFILE size {TAMANHO_MINIMO_DATAFILE} autoextend on next 1g maxsize {TAMANHO_MAXIMO_DATAFILE}';
		
		RAISE_ERRO_OTHERS EXCEPTION;
	
	BEGIN
	
		
		BEGIN
		
			v_STMT_DDL_CRIAR_DATAFILE := REPLACE( v_STMT_DDL_CRIAR_DATAFILE, '{NOME_TABLESPACE}', p_NOME_TABLESPACE );
			
			v_STMT_DDL_CRIAR_DATAFILE := REPLACE( v_STMT_DDL_CRIAR_DATAFILE, '{TAMANHO_MINIMO_DATAFILE}', v_TAMANHO_MINIMO_DATAFILE );
			
			v_STMT_DDL_CRIAR_DATAFILE := REPLACE( v_STMT_DDL_CRIAR_DATAFILE, '{TAMANHO_MAXIMO_DATAFILE}', v_TAMANHO_MAXIMO_DATAFILE );
			
			
			REGISTRAR_MSG_LOG( 'NOVO DATAFILE: ' || v_STMT_DDL_CRIAR_DATAFILE );
			
			
			IF NOT v_AMBIENTE_DE_TESTE THEN
			
				EXECUTE IMMEDIATE v_STMT_DDL_CRIAR_DATAFILE;
				
				
				REGISTRAR_MSG_LOG( 'Datafile criado com sucesso. Tablespace: ' || p_NOME_TABLESPACE );
				
			END IF;
			
		
		EXCEPTION
		
			WHEN OTHERS THEN
			
				REGISTRAR_MSG_LOG( 'Erro ao adicionar um novo DATAFILE. Nome tablespace: ' || p_NOME_TABLESPACE || '. Erro: ' || SQLERRM );
				
				RAISE RAISE_ERRO_OTHERS;
			
		
		END;
		
		
	
	END;
	
	
	
	PROCEDURE LISTAR_TABLESPACE AS
	
		CURSOR c_LISTA_TABLESPACE( p_PORCENTAGEM_MINIMA NUMBER ) IS
			SELECT
				TABLESPACE_NAME
			FROM
				(
					SELECT 
						 TABLESPACE_NAME
						,ROUND((NVL( ( MB_MAX - MB_USED_ALLOC ) , 0) / MB_MAX) * 100, 2) PCT_TOTAL_FREE
						FROM
						(
							SELECT 
								 TABLESPACE_NAME
								,MB_ALLOC
								,MB_FREE_ALLOC
								,MB_USED_ALLOC
								,PCT_FREE_MB_ALLOC 
								,PCT_USED_MB_ALLOC
								,CASE WHEN MB_MAX < MB_ALLOC THEN MB_ALLOC ELSE MB_MAX END MB_MAX
							FROM
								(   
									SELECT
										A.TABLESPACE_NAME TABLESPACE_NAME,
										ROUND(A.BYTES_ALLOC / 1024 / 1024, 2) MB_ALLOC,
										ROUND(NVL(B.BYTES_FREE, 0) / 1024 / 1024, 2) MB_FREE_ALLOC,
										ROUND((A.BYTES_ALLOC - NVL(B.BYTES_FREE, 0)) / 1024 / 1024, 2) MB_USED_ALLOC,
										ROUND((NVL(B.BYTES_FREE, 0) / A.BYTES_ALLOC) * 100, 2) PCT_FREE_MB_ALLOC,
										100 - ROUND((NVL(B.BYTES_FREE, 0) / A.BYTES_ALLOC) * 100, 2) PCT_USED_MB_ALLOC,
										ROUND(MAXBYTES / 1048576, 2) MB_MAX
									FROM
										(
											SELECT
												F.TABLESPACE_NAME,
												SUM(F.BYTES) BYTES_ALLOC,
												SUM( CASE WHEN MAXBYTES > BYTES THEN MAXBYTES ELSE BYTES END ) MAXBYTES
											FROM
												SYS.DBA_DATA_FILES F
											GROUP BY
												TABLESPACE_NAME
										)  A,
										(
											SELECT
												F.TABLESPACE_NAME,
												SUM(F.BYTES) BYTES_FREE
											FROM
												SYS.DBA_FREE_SPACE F
											GROUP BY
												TABLESPACE_NAME
										)  B
									WHERE
										A.TABLESPACE_NAME = B.TABLESPACE_NAME (+)
									UNION
									SELECT
										H.TABLESPACE_NAME,
										ROUND(SUM(H.BYTES_FREE + H.BYTES_USED) / 1048576, 2),
										ROUND(SUM((H.BYTES_FREE + H.BYTES_USED) - NVL(P.BYTES_USED, 0)) / 1048576, 2),
										ROUND(SUM(NVL(P.BYTES_USED, 0)) / 1048576, 2),
										ROUND((SUM((H.BYTES_FREE + H.BYTES_USED) - NVL(P.BYTES_USED, 0)) / SUM(H.BYTES_USED + H.BYTES_FREE)) * 100, 2),
										100 - ROUND((SUM((H.BYTES_FREE + H.BYTES_USED) - NVL(P.BYTES_USED, 0)) / SUM(H.BYTES_USED + H.BYTES_FREE)) * 100, 2),
										ROUND(MAX(H.BYTES_USED + H.BYTES_FREE) / 1048576, 2)
									FROM
										SYS.V_$TEMP_SPACE_HEADER    H,
										SYS.V_$TEMP_EXTENT_POOL     P
									WHERE
											P.FILE_ID (+) = H.FILE_ID
										AND P.TABLESPACE_NAME (+) = H.TABLESPACE_NAME
									GROUP BY
										H.TABLESPACE_NAME
								)
						)
				)
			WHERE
				PCT_TOTAL_FREE < p_PORCENTAGEM_MINIMA;
		

		
		
		v_REGISTRO_TABLESPACE c_LISTA_TABLESPACE%ROWTYPE;
		
		
		v_PORCENTAGEM_MINIMA_ALERTA_TABLESPACE CONSTANT NUMBER := 10;
	
		
		RAISE_ERRO_OTHERS EXCEPTION;
	
	BEGIN
	
		
		BEGIN
		
		
			OPEN c_LISTA_TABLESPACE( v_PORCENTAGEM_MINIMA_ALERTA_TABLESPACE );
			LOOP
			FETCH c_LISTA_TABLESPACE INTO v_REGISTRO_TABLESPACE;
			EXIT WHEN c_LISTA_TABLESPACE%NOTFOUND;
		
				
				REGISTRAR_MSG_LOG( 'Tablespace em alerta: ' || v_REGISTRO_TABLESPACE.TABLESPACE_NAME );
				
				
				ADICIONAR_NOVO_DATAFILE( v_REGISTRO_TABLESPACE.TABLESPACE_NAME );
				
			
			END LOOP;
			CLOSE c_LISTA_TABLESPACE;
			
		
		
		EXCEPTION
		
			WHEN OTHERS THEN
				
				REGISTRAR_MSG_LOG( 'Falha ao listar as tablespace. Erro: ' || SQLERRM );
				
				RAISE RAISE_ERRO_OTHERS;
		
		
		END;
	
	
	
	END;
	
	
	
	PROCEDURE VALIDAR_USO_DE_OMF AS
	
		v_LOCAL_CRIAR_TABLESPACE VARCHAR2(4000);
	
		RAISE_ERRO_OMF_DESABILITADO EXCEPTION;
		
		RAISE_ERRO_OTHERS EXCEPTION;
	
	BEGIN
	
	
		BEGIN
		
			
			-- ##
			--
			-- Verifica se o parâmetro para criação de TABLESPACE foi definido - DB_CREATE_FILE_DEST
			BEGIN
				
			
				SELECT VALUE INTO v_LOCAL_CRIAR_TABLESPACE FROM SYS.GV_$PARAMETER WHERE UPPER( NAME ) = 'DB_CREATE_FILE_DEST';
			
			
				IF v_LOCAL_CRIAR_TABLESPACE IS NULL THEN
					RAISE RAISE_ERRO_OMF_DESABILITADO;
				END IF;
				
			
			EXCEPTION
			
			
				WHEN NO_DATA_FOUND THEN
				
					REGISTRAR_MSG_LOG( 'OMF não está habilitado ou não foi definido. Defina um valor para o parâmetro DB_CREATE_FILE_DEST.' );
				
					RAISE RAISE_ERRO_OMF_DESABILITADO;
					
					
				WHEN OTHERS THEN
			
					REGISTRAR_MSG_LOG( 'Erro ao acessar a tabela GV_$PARAMETER para validar o cliente. Sigla: ' || CLIENTE_INFO.GET_SIGLA || ' Erro > ' ||  SQLERRM );
										
					RAISE RAISE_ERRO_OTHERS;
					
					
			END;
		
		EXCEPTION
		
			WHEN OTHERS THEN
				
				REGISTRAR_MSG_LOG( 'Erro ao validar o OMF. Erro: ' ||  SQLERRM );
										
				RAISE RAISE_ERRO_OTHERS;
		
		
		END;
		
	
	
	END;
	
	
	
	
	PROCEDURE GERENCIAR( p_AMBIENTE_DE_TESTE BOOLEAN ) AS
	BEGIN
		
		
		BEGIN
			
			v_AMBIENTE_DE_TESTE := p_AMBIENTE_DE_TESTE;
			
		
			VALIDAR_USO_DE_OMF;
			
			
			LISTAR_TABLESPACE;
			
		EXCEPTION
		
			WHEN OTHERS THEN
			
				REGISTRAR_MSG_LOG( 'Falha no processo de gerenciamento. Erro: ' || SQLERRM );
		
		END;
		
	END;
	
	


END WDS_GESTAO_EXPANSAO_TABLESPACE;
/


	
	
	
	
	
	
	
	
	