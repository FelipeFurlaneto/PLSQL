SET SERVEROUTPUT ON
DECLARE
CURSOR C_Geral IS
    (SELECT SAC.NR_SAC,
    SAC.dt_abertura_sac,
    SAC.hr_abertura_sac,
    SAC.tp_sac,
    PRD.cd_produto,
    PRD.ds_produto,
    PRD.vl_unitario,
    PRD.vl_perc_lucro,
    CLI.nr_cliente,
    CLI.nm_cliente
    FROM MC_SGV_SAC SAC LEFT JOIN MC_PRODUTO PRD 
    ON SAC.CD_PRODUTO = PRD.CD_PRODUTO
    LEFT JOIN MC_CLIENTE CLI ON SAC.NR_CLIENTE = CLI.NR_CLIENTE);
    
sg_estado CHAR(2);
nm_estado VARCHAR2(30);
classificacao_sac VARCHAR2(30);
vl_perc_icms_estado NUMBER;
vl_icms_produto NUMBER;
ds_tipo_classificacao_sac VARCHAR2(30);
vl_unitario_lucro_produto NUMBER;
v_estado CHAR(2);

BEGIN

FOR j IN C_Geral LOOP

vl_unitario_lucro_produto := (j.vl_perc_lucro/100)*j.vl_unitario;

CASE j.tp_sac
    WHEN 'S' THEN classificacao_sac := 'SUGESTÃO';
    WHEN 'D' THEN classificacao_sac := 'DÚVIDA';
    WHEN 'E' THEN classificacao_sac := 'ELOGIO';
    ELSE classificacao_sac := 'CLASSIFICAÇÃO INVÁLIDA';
    END CASE;

SELECT mc_estado.sg_estado
INTO v_estado
FROM MC_END_CLI EC
LEFT JOIN MC_LOGRADOURO ON EC.CD_LOGRADOURO_CLI = MC_LOGRADOURO.CD_LOGRADOURO
LEFT JOIN mc_bairro ON mc_logradouro.cd_bairro = mc_bairro.cd_bairro
LEFT JOIN mc_cidade ON mc_bairro.cd_cidade = mc_cidade.cd_cidade
LEFT JOIN mc_estado ON mc_cidade.sg_estado = mc_estado.sg_estado
WHERE EC.nr_cliente = j.nr_cliente;

SELECT mc_estado.nm_estado
INTO nm_estado
FROM MC_END_CLI EC
LEFT JOIN MC_LOGRADOURO ON EC.CD_LOGRADOURO_CLI = MC_LOGRADOURO.CD_LOGRADOURO
LEFT JOIN mc_bairro ON mc_logradouro.cd_bairro = mc_bairro.cd_bairro
LEFT JOIN mc_cidade ON mc_bairro.cd_cidade = mc_cidade.cd_cidade
LEFT JOIN mc_estado ON mc_cidade.sg_estado = mc_estado.sg_estado
WHERE EC.nr_cliente = j.nr_cliente;

vl_perc_icms_estado := pf0110.fun_mc_gera_aliquota_media_icms_estado(v_estado);
vl_icms_produto := (vl_perc_icms_estado/100) * j.vl_unitario;

    DBMS_OUTPUT.PUT_LINE ('Número da ocorrência do SAC:  ' || j.nr_sac);
    DBMS_OUTPUT.PUT_LINE ('Data de abertura do SAC:  ' || j.dt_abertura_sac);
    DBMS_OUTPUT.PUT_LINE ('Hora de abertura do SAC:  ' || j.hr_abertura_sac);
    DBMS_OUTPUT.PUT_LINE ('Tipo do SAC:  ' || j.tp_sac);
    DBMS_OUTPUT.PUT_LINE ('Código do produto:  ' || j.cd_produto);
    DBMS_OUTPUT.PUT_LINE ('Nome do produto:  ' || j.ds_produto);
    DBMS_OUTPUT.PUT_LINE ('Valor unitário do produto:  ' || j.vl_unitario);
    DBMS_OUTPUT.PUT_LINE ('Percentual do lucro unitário do produto:  ' || j.vl_perc_lucro);
    DBMS_OUTPUT.PUT_LINE ('Número do Cliente:  ' || j.nr_cliente);
    DBMS_OUTPUT.PUT_LINE ('Nome do Cliente:  ' || j.nm_cliente);
    DBMS_OUTPUT.PUT_LINE('perc lucro: '|| vl_unitario_lucro_produto);
    DBMS_OUTPUT.PUT_LINE('classificacao sac: '|| classificacao_sac);
    DBMS_OUTPUT.PUT_LINE('vl imcs estado: '|| vl_perc_icms_estado);
    DBMS_OUTPUT.PUT_LINE('v icms produto: '|| vl_icms_produto);
    DBMS_OUTPUT.PUT_LINE('***********************');

INSERT INTO MC_SGV_OCORRENCIA_SAC (NR_OCORRENCIA_SAC,DT_ABERTURA_SAC, HR_ABERTURA_SAC,DS_TIPO_CLASSIFICACAO_SAC,DS_INDICE_SATISFACAO_ATD_SAC,CD_PRODUTO,DS_PRODUTO,VL_UNITARIO_PRODUTO,VL_PERC_LUCRO,VL_UNITARIO_LUCRO_PRODUTO,SG_ESTADO,NM_ESTADO,NR_CLIENTE,NM_CLIENTE,VL_ICMS_PRODUTO)
VALUES (j.nr_sac, j.dt_abertura_sac,j.hr_abertura_sac, j.tp_sac,NULL,j.cd_produto, j.ds_produto, j.vl_unitario, j.vl_perc_lucro,vl_unitario_lucro_produto,v_estado,nm_estado, j.nr_cliente, j.nm_cliente,vl_icms_produto);

END LOOP;
COMMIT;

EXCEPTION 

WHEN OTHERS THEN ROLLBACK;

END;