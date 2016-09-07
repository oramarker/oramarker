create or replace PACKAGE BODY ORAMARKER_LOG_PKG AS

  v_log_level INTEGER := c_info;
  
  PROCEDURE PRT(p_msg VARCHAR2) IS
  BEGIN
   DBMS_OUTPUT.PUT_LINE(p_msg);
  END PRT;
  PROCEDURE INFO(p_msg VARCHAR2) AS
  BEGIN
    if v_log_level >= c_info then
      prt(p_msg);
    end if;
  END INFO;

  PROCEDURE DEBUG(p_msg VARCHAR2) AS
  BEGIN
    if v_log_level >= c_debug then
      prt(p_msg);
    end if;
  END DEBUG;

  PROCEDURE ERROR(p_msg VARCHAR2) AS
  BEGIN
    if v_log_level >= c_error then
      prt(p_msg);
    end if;
  END ERROR;

END ORAMARKER_LOG_PKG;
/