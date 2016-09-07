CREATE OR REPLACE PACKAGE ORAMARKER_PKG AS
-- QUOTE_CHARS CONSTANT VARCHAR2(200) := '{|[<(/@#$%&*';
LF CONSTANT CHAR(1) := CHR(10);
SUBTYPE  LINE_TEXT_T IS VARCHAR2(2000);
TYPE TEXT_LIST_T IS TABLE OF LINE_TEXT_T;
TYPE argument_curtype IS REF CURSOR  RETURN USER_ARGUMENTS%ROWTYPE;

PROCEDURE MERGE_TEXT(p_template VARCHAR2,p_anydata_map ANYDATA_MAP_T,p_clob_out OUT NOCOPY CLOB);
PROCEDURE COMPILE_TEMPLATE(p_proc_name VARCHAR2, p_target_proc_name VARCHAR2);
PROCEDURE COMPILE_TEMPLATE(p_pkg_name VARCHAR2,p_proc_name VARCHAR2, p_target_proc_name VARCHAR2);
PROCEDURE GET_TEXT_FROM_PROC(p_proc_name VARCHAR,p_anydata_map ANYDATA_MAP_T, p_clob_out OUT NOCOPY CLOB) ;
PROCEDURE GET_TEXT_FROM_PKG_PROC(p_pkg_name VARCHAR2,p_proc_name VARCHAR,p_anydata_map ANYDATA_MAP_T, p_clob_out OUT NOCOPY CLOB) ;
END ORAMARKER_PKG;
/