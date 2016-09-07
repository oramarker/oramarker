CREATE OR REPLACE TYPE ANYDATA_T force AS OBJECT (
NAME VARCHAR2(30),
DATA ANYDATA
);
/

CREATE OR REPLACE TYPE ANYDATA_LIST_T AS TABLE OF ANYDATA_T;
/
CREATE OR REPLACE TYPE ANYDATA_MAP_T FORCE AS OBJECT (
data_list ANYDATA_LIST_T,
CONSTRUCTOR FUNCTION ANYDATA_MAP_T (SELF IN OUT NOCOPY ANYDATA_MAP_T) RETURN SELF AS RESULT,


MEMBER PROCEDURE prv_PUT_ANYDATA(p_name VARCHAR2, p_anydata ANYDATA),
MEMBER FUNCTION prv_GET_ANYDATA(p_name VARCHAR2) RETURN ANYDATA,

MEMBER FUNCTION NAME_EXISTS(p_name VARCHAR2) RETURN BOOLEAN,
MEMBER FUNCTION GET_COUNT RETURN INTEGER,

MEMBER PROCEDURE PUT_VARCHAR2(p_name VARCHAR2, p_varchar VARCHAR2),
MEMBER PROCEDURE PUT_CLOB(p_name VARCHAR2, p_clob VARCHAR2),
MEMBER PROCEDURE PUT_DATE(p_name VARCHAR2, p_date DATE),
MEMBER PROCEDURE PUT_TIMESTAMP(p_name VARCHAR2, p_timestamp TIMESTAMP),

MEMBER FUNCTION GET_VARCHAR2(p_name VARCHAR2) RETURN VARCHAR2,
MEMBER FUNCTION GET_DATE(p_name VARCHAR2) RETURN DATE,
MEMBER PROCEDURE GET_CLOB(p_name VARCHAR2, p_clob_out OUT NOCOPY CLOB) ,
MEMBER FUNCTION GET_TIMESTAMP(p_name VARCHAR2) RETURN TIMESTAMP,

MEMBER FUNCTION GET_DATA_LIST RETURN ANYDATA_LIST_T

);
/


