oramarker
=========
What is oramarker?

Oramarker is a template engine written in ORACLE PL/SQL and for  PL SQL.

Why build oramarker?

Compared to java or any other languages, PL/SQL lacks a template library similar to Velocity (http://velocity.apache.org) to generate text content from templates. From time to time , I find PL/SQL developers building dynamic SQL statements with text concatenations. It is error prone and hard to read and maintain. Why not just building a similar template engine in PL/SQL? 

Installation

Install the following packages and types.
Install follwing files:

1. any_data_map_t.sql and ANYDATA_MAP_T_BODY.sql  -- Creates object types anydata_t, anydata_list_t,anydata_map_t
2. ORAMARKER_PKG.sql and ORAMARKER_PKG_body.sql   -- Creates package oramarker_pkg
3. (Optional) Test template package TEMPLATE_REPO_PKG.sql TEMPLATE_REPO_PKG_body.sql  -- Create a templage package

How to use oramarer?

There are two approaches to use oramarker.

1. Simple text merge .

    declare
       v_anydata_map ANYDATA_MAP_T;
v_template VARCHAR2(32667);
v_text VARCHAR2(32667);
v_clob CLOB;
BEGIN
 
      v_anydata_map := new ANYDATA_MAP_T;
      
      v_anydata_map.PUT_VARHCAR('name', 'John');
      v_anydata_map.PUT_DATE('birthdate', sysdate);
      v_anydata_map.PUT_VARHCAR('city', 'New York');
      
      v_template := q'[ Hello ${Name},!' your birth date is: ${to_char(birthdate,'YYYY-MM-dd') }]';
      ORAMARKER_PKG.MERGE_TEXT(v_template,v_anydata_map,v_clob);
      ORAMARKER_LOG_PKG.info(v_clob);

   end;
   
2. Complext template approach.

If the template need to conain if/else or loop statments, the template is defined in the procedures or procedures in package.

Here is the example contains in soruce code.

create or replace PACKAGE BODY TEMPLATE_REPO_PKG AS

PROCEDURE WELCOME_EMAIL(p_name VARCHAR2, p_city VARCHAR2, p_birth_date DATE) IS

v_totalcount INTEGER;
BEGIN
--  HELLO ${p_name}
--## This is comment
IF p_city = 'Beijing' THEN
   NULL;
-- You are in Beijing
ELSE
   NULL;
-- Wow, you are in ${p_city}, not in Beijing
END IF;
--  Welcome to ${p_city}, happy birthday: ${to_char(p_birth_date,'yyyy-MM-dd')}
--  unbundled 
NULL;
for i in 1..10 loop
NULL;
-- count ${i}
end loop;

END WELCOME_EMAIL;
 
END TEMPLATE_REPO_PKG;


Here is code to generate content.

  v_anydata_map.PUT_VARHCAR('p_name', 'John');
  v_anydata_map.PUT_DATE('P_BIRTH_DATE', sysdate);
  v_anydata_map.PUT_VARHCAR('p_city', 'New York');
  ORAMARKER_PKG.GET_TEXT_FROM_PKG_PROC('TEMPLATE_REPO_PKG','WELCOME_EMAIL',v_anydata_map,v_clob);
  
  --ORAMARKER_LOG_PKG.info(v_clob);
  
  
  
  ORAMARKER_PKG.GET_TEXT_FROM_PROC('WELCOME_EMAIL_SP',v_anydata_map,v_clob);
  ORAMARKER_LOG_PKG.info('TEST FOR STANALONE PROCEDURE');
  ORAMARKER_LOG_PKG.info(v_clob);











