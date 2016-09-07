
CREATE OR REPLACE TYPE BODY ANYDATA_MAP_T  AS 

 CONSTRUCTOR FUNCTION ANYDATA_MAP_T (SELF IN OUT NOCOPY ANYDATA_MAP_T) RETURN SELF AS RESULT
  IS
  BEGIN
    data_list := ANYDATA_LIST_T();
    RETURN ;
  END;

 
 
 
MEMBER PROCEDURE prv_PUT_ANYDATA(p_name VARCHAR2, p_anydata ANYDATA) IS
  v_any_data_t ANYDATA_T;
  v_name VARCHAR2(200) := LOWER(p_name);
 BEGIN 
  IF  NOT NAME_EXISTS(v_name) THEN
    v_any_data_t := NEW ANYDATA_T(v_name,p_anydata);
    data_list.EXTEND(1);
    data_list(data_list.count) := v_any_data_t;
  ELSE
     -- UPDATE
     FOR I IN 1..data_list.COUNT loop
       IF data_list(i).NAME = v_name THEN
          data_list(i).DATA := p_anydata;
          EXIT;
       END IF;
     END loop;
  END IF;
   
   NULL;
 END prv_PUT_ANYDATA;

MEMBER FUNCTION prv_GET_ANYDATA(p_name VARCHAR2) RETURN ANYDATA IS
v_anydata ANYDATA;
BEGIN

FOR I IN 1..data_list.COUNT loop
       IF data_list(i).NAME = p_name THEN
          v_anydata := data_list(i).DATA ;
          EXIT;
       END IF;
END loop;
return v_anydata;
END;

MEMBER FUNCTION NAME_EXISTS(p_name VARCHAR2) RETURN BOOLEAN IS
 v_name VARCHAR2(200) := LOWER(p_name);
BEGIN

FOR I IN 1..data_list.COUNT loop
       IF data_list(i).NAME = v_name THEN
          return true;
       END IF;
END loop;
return false;

END;

MEMBER FUNCTION GET_COUNT RETURN INTEGER IS
BEGIN
RETURN data_list.count;
END;
 
 

MEMBER PROCEDURE PUT_VARCHAR2(p_name VARCHAR2, p_varchar VARCHAR2) IS
BEGIN 
self.prv_PUT_ANYDATA (p_name,ANYDATA.CONVERTVARCHAR2(p_varchar));
END PUT_VARCHAR2;

MEMBER PROCEDURE PUT_CLOB(p_name VARCHAR2, p_clob VARCHAR2) IS
BEGIN 
self.prv_PUT_ANYDATA (p_name,ANYDATA.CONVERTCLOB(p_CLOB));
END PUT_CLOB;

MEMBER PROCEDURE PUT_DATE(p_name VARCHAR2, p_date DATE) IS
BEGIN 
self.prv_PUT_ANYDATA (p_name,ANYDATA.CONVERTDATE(p_date));
END PUT_DATE;

MEMBER PROCEDURE PUT_TIMESTAMP(p_name VARCHAR2, p_timestamp TIMESTAMP) IS
BEGIN 
self.prv_PUT_ANYDATA (p_name,ANYDATA.CONVERTTIMESTAMP(p_timestamp));
END PUT_TIMESTAMP;

MEMBER FUNCTION GET_VARCHAR2(p_name VARCHAR2) RETURN VARCHAR2 IS
v_anydata ANYDATA;
BEGIN 
v_anydata := prv_GET_ANYDATA(p_name);
IF v_anydata IS NULL THEN
  RETURN NULL;
ELSE
   IF  SYS.ANYDATA.GETTYPENAME (v_anydata) <> 'SYS.VARCHAR2' THEN
        RAISE_APPLICATION_ERROR(-20100, 'Found type:' || SYS.ANYDATA.GETTYPENAME (v_anydata) || ' instead of VARCHAR2');
   ELSE
        RETURN ANYDATA.accessvarchar2(v_anydata);
   END IF; 
END IF;

END GET_VARCHAR2;

MEMBER FUNCTION GET_DATE(p_name VARCHAR2) RETURN DATE IS
v_anydata ANYDATA;
BEGIN 
v_anydata := prv_GET_ANYDATA(p_name);
IF v_anydata IS NULL THEN
  RETURN NULL;
ELSE
   IF  SYS.ANYDATA.GETTYPENAME (v_anydata) <> 'SYS.DATE' THEN
        RAISE_APPLICATION_ERROR(-20100, 'Found type:' || SYS.ANYDATA.GETTYPENAME (v_anydata) || ' instead of DATE');
   ELSE
        RETURN ANYDATA.accessDATE(v_anydata);
   END IF; 
END IF;
END GET_DATE;

MEMBER PROCEDURE GET_CLOB(p_name VARCHAR2, p_clob_out OUT NOCOPY CLOB) IS
v_anydata ANYDATA;
v_dummy PLS_INTEGER;
BEGIN 
v_anydata := prv_GET_ANYDATA(p_name);
IF v_anydata IS NULL THEN
  p_clob_out := NULL;
ELSE
   IF  SYS.ANYDATA.GETTYPENAME (v_anydata) <> 'SYS.CLOB' THEN
        RAISE_APPLICATION_ERROR(-20100, 'Found type:' || SYS.ANYDATA.GETTYPENAME (v_anydata) || ' instead of CLOB');
   ELSE
       v_dummy := ANYDATA.getclob(v_anydata,p_clob_out);
   END IF; 
END IF;
END GET_CLOB;

MEMBER FUNCTION GET_TIMESTAMP(p_name VARCHAR2) RETURN TIMESTAMP IS
v_anydata ANYDATA;
BEGIN 
v_anydata := prv_GET_ANYDATA(p_name);
IF v_anydata IS NULL THEN
  RETURN NULL;
ELSE
   IF  SYS.ANYDATA.GETTYPENAME (v_anydata) <> 'SYS.TIMESTAMP' THEN
        RAISE_APPLICATION_ERROR(-20100, 'Found type:' || SYS.ANYDATA.GETTYPENAME (v_anydata) || ' instead of TIMESTAMP');
   ELSE
        RETURN ANYDATA.accessTIMESTAMP(v_anydata);
   END IF; 
END IF;
END GET_TIMESTAMP;

MEMBER FUNCTION GET_DATA_LIST RETURN ANYDATA_LIST_T IS
BEGIN
RETURN data_list;
END GET_DATA_LIST;

END ;
/