create or replace PROCEDURE ORAMARKER_TEST_SP AS 
v_anydata_map ANYDATA_MAP_T;
v_template VARCHAR2(32667);
v_text VARCHAR2(32667);
v_clob CLOB;
BEGIN
  NULL;
  
  v_anydata_map := new ANYDATA_MAP_T;
  
  v_anydata_map.PUT_VARCHAR2('name', 'John');
  v_anydata_map.PUT_DATE('birthdate', sysdate);
  v_anydata_map.PUT_VARCHAR2('city', 'New York');
  
  v_template := q'[ Hello ${Name},!' your birth date is: ${to_char(birthdate,'YYYY-MM-dd') }]';
  ORAMARKER_PKG.MERGE_TEXT(v_template,v_anydata_map,v_clob);
 -- ORAMARKER_LOG_PKG.info(v_clob);


  v_anydata_map.PUT_VARCHAR2('p_name', 'John');
  v_anydata_map.PUT_DATE('P_BIRTH_DATE', sysdate);
  v_anydata_map.PUT_VARCHAR2('p_city', 'New York');
  ORAMARKER_PKG.GET_TEXT_FROM_PKG_PROC('TEMPLATE_REPO_PKG','WELCOME_EMAIL',v_anydata_map,v_clob);
  
  --ORAMARKER_LOG_PKG.info(v_clob);
  
  
  
  ORAMARKER_PKG.GET_TEXT_FROM_PROC('WELCOME_EMAIL_SP',v_anydata_map,v_clob);
  ORAMARKER_LOG_PKG.info('TEST FOR STANALONE PROCEDURE');
  ORAMARKER_LOG_PKG.info(v_clob);
  
  
  
END ORAMARKER_TEST_SP;
/