CREATE OR REPLACE PACKAGE BODY TEMPLATE_REPO_PKG AS

PROCEDURE WELCOME_EMAIL(p_name VARCHAR2, p_city VARCHAR2, p_birth_date DATE) IS
BEGIN
--@  HELLO ${p_name}
--# This is comment
--@  Welcome to ${p_city}, happy birthday: ${to_char(p_birth_date,'yyyy-MM-dd')}
NULL;
END WELCOME_EMAIL;
 
END TEMPLATE_REPO_PKG; 
/