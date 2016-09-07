CREATE OR REPLACE PACKAGE BODY ORAMARKER_PKG AS

FUNCTION GET_SPACE(p_num INTEGER) RETURN VARCHAR AS
v_ret_txt VARCHAR2(10);
v_count INTEGER;
BEGIN
v_count := 10 - LENGTH(TO_CHAR(p_num));
FOR I IN 1..v_count LOOP
  v_ret_txt := v_ret_txt || ' ';
END LOOP;
  v_ret_txt  := v_ret_txt || p_num;
RETURN v_ret_txt;
END GET_SPACE;

PROCEDURE SHOW_SQL(p_sql CLOB) AS
v_count  INTEGER := 1;
v_line LINE_TEXT_T;
BEGIN

LOOP
 v_line := REGEXP_SUBSTR(p_sql,'[[:print:]]*' || CHR(13) || '?' || LF,1, v_count);
 EXIT WHEN v_line IS NULL;
 ORAMARKER_LOG_PKG.INFO( GET_SPACE(v_count) || ' | ' || v_line);
 v_count := v_count + 1;

END LOOP;

END SHOW_SQL;

FUNCTION GET_LINE_NUM_TEXT(p_line_num IN OUT INTEGER) RETURN VARCHAR2 IS
BEGIN
 p_line_num := p_line_num + 1;
RETURN '/* ' || p_line_num || ' */  ';
END GET_LINE_NUM_TEXT;

FUNCTION GET_PKG_PROC_ARG_CURSOR(p_pkg_name VARCHAR2,p_proc_name VARCHAR2) RETURN sys_refcursor IS
v_cur argument_curtype;

BEGIN
IF p_pkg_name IS NOT NULL THEN
  OPEN  v_cur FOR SELECT *  FROM USER_ARGUMENTS
                    WHERE package_name =  upper(p_pkg_name)
                         AND object_name = upper(p_proc_name)
                    ORDER BY POSITION ;
ELSE
   OPEN  v_cur FOR SELECT * FROM USER_ARGUMENTS
                    WHERE package_name IS NULL
                         AND object_name = upper(p_proc_name)
                    ORDER BY POSITION ;
END IF;
RETURN v_cur;
END GET_PKG_PROC_ARG_CURSOR;


PROCEDURE CHECK_BIND_VARS(p_pkg_name_i VARCHAR2, p_proc_name_i VARCHAR2,p_anydata_map ANYDATA_MAP_T) IS
/*CURSOR v_arg_cur IS SELECT ARGUMENT_NAME,DATA_TYPE FROM USER_ARGUMENTS
                    WHERE package_name =  upper(p_pkg_name_i)
                         AND object_name = upper(p_proc_name_i)
                    ORDER BY POSITION ;
 */                    
v_msg VARCHAR2(2000);                    
v_lf constant CHAR(1) := CHR(10);
v_data_type VARCHAR2(30);

v_arg_cur_t argument_curtype;
v_arg_rec USER_ARGUMENTS%ROWTYPE;
BEGIN

  v_arg_cur_t :=  GET_PKG_PROC_ARG_CURSOR(p_pkg_name_i, p_proc_name_i);
  LOOP
   FETCH v_arg_cur_t INTO v_arg_rec;
   EXIT WHEN v_arg_cur_t%NOTFOUND;
     IF NOT p_anydata_map.name_exists(lower(v_arg_rec.argument_name)) THEN
      IF v_msg IS NOT NULL THEN
        v_msg := v_msg || ',';
      END IF ;
       v_msg := v_msg || v_arg_rec.argument_name;
     END IF;
  
  END LOOP;
  CLOSE v_arg_cur_t;

/*
FOR rec IN v_arg_cur LOOP

 IF NOT p_anydata_map.name_exists(lower(rec.argument_name)) THEN
  IF v_msg IS NOT NULL THEN
    v_msg := v_msg || ',';
  END IF ;
   v_msg := v_msg || rec.argument_name;
 END IF;
  

END loop;
 */
  IF v_msg IS NOT NULL THEN
    RAISE_APPLICATION_ERROR(-20101, 'No value(s) provided:' || v_msg);
  END IF;
 

END CHECK_BIND_VARS;



FUNCTION  IS_TEXT_LINE(p_line_i VARCHAR2) RETURN BOOLEAN IS
v_line LINE_TEXT_T := trim(REPLACE(p_line_i,chr(9),'   '));
BEGIN
IF v_line IS NOT NULL AND SUBSTR(v_line,1,3) = '--@' THEN
  RETURN TRUE;
ELSE 
  RETURN FALSE;
end if;
END IS_TEXT_LINE;

FUNCTION  IS_COMMENT_LINE(p_line_i VARCHAR2) RETURN BOOLEAN IS
v_line LINE_TEXT_T := trim(REPLACE(p_line_i,chr(9),'   '));
BEGIN
IF v_line IS NOT NULL AND SUBSTR(v_line,1,3) = '--#' THEN
  RETURN TRUE;
ELSE 
  RETURN FALSE;
end if;
END IS_COMMENT_LINE;



FUNCTION  IS_NULL_LINE(p_line_i VARCHAR2) RETURN BOOLEAN
IS
BEGIN
IF REGEXP_INSTR(p_line_i, '^ *null *; *$',1,1,0,'i') > 0 THEN
  RETURN TRUE;
ELSE 
  RETURN FALSE;
END IF;
END IS_NULL_LINE;

FUNCTION GET_PROC_SOURCE_PROC(p_proc_name VARCHAR2) RETURN TEXT_LIST_T IS
v_src_list TEXT_LIST_T;
 l_index   PLS_INTEGER ;
 v_reg_text VARCHAR2(30) := '^ *END *[;|'|| p_proc_name|| ']';
BEGIN
     SELECT text BULK COLLECT INTO v_src_list
    FROM USER_SOURCE 
    WHERE NAME = p_proc_name
     AND TYPE = 'PROCEDURE'
    ORDER BY line;


  ORAMARKER_LOG_PKG.INFO('lines from proc:'|| v_src_list.count);

  l_index := v_src_list.LAST;
   WHILE (l_index IS NOT NULL)   LOOP
      IF REGEXP_INSTR(v_src_list(l_index),v_reg_text,1,1,0,'i') > 0 then
          --ORAMARKER_LOG_PKG.INFO('MATCHED' || v_src_list(l_index));
          v_src_list.delete(l_index);
          EXIT;
      END IF;
      l_index := v_src_list.PRIOR (l_index);
   END LOOP;


  
  RETURN v_src_list;
END GET_PROC_SOURCE_PROC;



FUNCTION GET_PROC_SOURCE(p_pkg_name_i VARCHAR2, p_proc_name VARCHAR2) RETURN TEXT_LIST_T IS
v_src_list TEXT_LIST_T;
v_start_num INTEGER;
v_end_num INTEGER;
BEGIN

-- get start line
BEGIN
    SELECT LINE INTO v_start_num
    FROM USER_SOURCE 
    WHERE NAME = p_pkg_name_i
       AND REGEXP_LIKE( text,'.*PROCEDURE +' || p_proc_name,'ni')
       AND TYPE = 'PACKAGE BODY';
 EXCEPTION 
    WHEN NO_DATA_FOUND  THEN
        RAISE_APPLICATION_ERROR(-20004, 'No source code found for package/proc:' || p_pkg_name_i || '/' || p_proc_name);  
 END;       
 
 
-- Gets end line 
BEGIN 
   SELECT LINE INTO v_end_num 
   FROM USER_SOURCE 
    WHERE NAME = p_pkg_name_i
       AND TYPE = 'PACKAGE BODY'
       AND regexp_like( text,'^ *END +' || p_proc_name,'i');
  EXCEPTION 
    WHEN NO_DATA_FOUND  THEN
       RAISE_APPLICATION_ERROR(-20004, 'No end line found for package/proc:' || p_pkg_name_i || '/' || p_proc_name);  
 END;
 
     SELECT text BULK COLLECT INTO v_src_list
    FROM USER_SOURCE 
    WHERE NAME = p_pkg_name_i
     AND TYPE = 'PACKAGE BODY'
    AND line BETWEEN v_start_num AND (v_end_num - 1)
    ORDER BY line;

RETURN v_src_list;
END GET_PROC_SOURCE;





FUNCTION GET_QUOTE_CHAR(p_line_i VARCHAR2) RETURN VARCHAR2 IS
v_char CHAR(1);
BEGIN
  -- printable characters
	FOR I IN 33..126 LOOP
	v_char := chr(i);
	IF INSTR(p_line_i,v_char || '''') = 0 THEN
	 RETURN v_char;
	END IF;
	END LOOP;
	 RAISE_APPLICATION_ERROR(-20100,'Unable to find quoted char');
END GET_QUOTE_CHAR;

FUNCTION GET_QUOTE_CHAR_SUFFIX(p_char_i char) RETURN char IS
BEGIN
RETURN CASE WHEN p_char_i = '{' THEN       '}'
	          WHEN p_char_i = '[' THEN       ']'
	          WHEN p_char_i = '(' THEN       ')'
            WHEN p_char_i = '<' THEN       '>'		   
	          ELSE		   p_char_i
       END;		
end GET_QUOTE_CHAR_SUFFIX;

FUNCTION GET_DECLARE_BLOCK(p_data_list ANYDATA_LIST_T) RETURN VARCHAR2 IS
v_anydata_t ANYDATA_T;
v_text VARCHAR2(32667);
v_data_type  VARCHAR2(70);
v_data_list ANYDATA_LIST_T;
BEGIN

FOR i IN 1..p_data_list.COUNT LOOP
  v_anydata_t := p_data_list(i);
  
  v_data_type := ANYDATA.GETTYPENAME (v_anydata_t.DATA);
  v_data_type := REPLACE(v_data_type,'SYS.' ,'');
  IF(v_data_type = 'VARCHAR2') THEN
   v_data_type := v_data_type || '(32667)';
  END IF;
  v_text := v_text || v_anydata_t.NAME || ' ' || v_data_type || ' :=  :' || v_anydata_t.NAME || ';' || LF;
  
END LOOP;
return v_text;
END GET_DECLARE_BLOCK; 



FUNCTION TRANSLATE_TEXT_LINE(p_line_i VARCHAR2,p_remove_comment BOOLEAN DEFAULT FALSE) RETURN VARCHAR2 IS
v_new_line LINE_TEXT_T := replace(p_line_i,chr(9),'    ');

v_quote_char CHAR(3) := 'q''' || GET_QUOTE_CHAR(p_line_i);
v_quote_char_suffix CHAR(2) :=  GET_QUOTE_CHAR_SUFFIX(GET_QUOTE_CHAR(p_line_i)) || '''';
v_new_value  VARCHAR2(200) := v_quote_char_suffix || ' || ' || '\1' || ' || ' ||  v_quote_char;

BEGIN
  -- Remove  comment --
  IF p_remove_comment THEN
    v_new_line := regexp_replace(v_new_line,  '^( *)-{2,}@(.*)','\1\2',1,1,'in');
  END IF;
  v_new_line := regexp_replace(v_new_line, '\$\{([^\}]+)\}',v_new_value,1,0,'in');
  v_new_line := 'v_ret_text := v_ret_text ||' || v_quote_char || v_new_line || v_quote_char_suffix || ';' || LF;
 
RETURN v_new_line;
END TRANSLATE_TEXT_LINE;


FUNCTION TRANSLATE_COMMENT_LINE(p_line_i VARCHAR2) RETURN VARCHAR2 is
v_new_line LINE_TEXT_T := p_line_i;

v_quote_char CHAR(3) := 'q''' || GET_QUOTE_CHAR(p_line_i);
v_quote_char_suffix CHAR(2) :=  GET_QUOTE_CHAR_SUFFIX(GET_QUOTE_CHAR(p_line_i)) || '''';
v_new_value  VARCHAR2(200) :=  '\1--\2';

BEGIN

  v_new_line := regexp_replace(v_new_line, '(^ )*--#(.*)$',v_new_value,1,0,'in');
  v_new_line := 'v_ret_text := v_ret_text ||' || v_quote_char || v_new_line || v_quote_char_suffix || ';' || LF;
 
RETURN v_new_line;
END TRANSLATE_COMMENT_LINE;




FUNCTION TRANSLATE_LINES(p_line_list_i TEXT_LIST_T) RETURN TEXT_LIST_T IS
v_new_line_list TEXT_LIST_T := TEXT_LIST_T();
v_line LINE_TEXT_T;
v_new_line LINE_TEXT_T;
BEGIN
v_new_line_list.EXTEND(p_line_list_i.count);
 
FOR indx IN 1..p_line_list_i.count loop
  v_line := p_line_list_i(indx);
  --IF v_line is not NULL  and  SUBSTR(v_line,-1,1) = LF THEN
  --  v_line := SUBSTR(v_line,1,LENGTH(v_line)-1);
  --END IF;
  
  IF v_line IS NULL OR TRIM(v_line) IS NULL THEN
    v_new_line := v_line;
  elsIF IS_NULL_LINE(v_line) THEN
    v_new_line := 'NULL;';
  ELSIF IS_COMMENT_LINE(v_line) THEN
    v_new_line := TRANSLATE_COMMENT_LINE(v_line);
  ELSIF IS_TEXT_LINE(v_line) THEN
    v_new_line := TRANSLATE_TEXT_LINE(v_line,TRUE);
  ELSE 
    -- PL SQL CODE
   v_new_line := v_line;
  end if;
  
    v_new_line_list(indx) := v_new_line ;
END loop;

return v_new_line_list;
END TRANSLATE_LINES;




FUNCTION GET_DECLARE_BLOCK(p_pkg_name_i VARCHAR2, p_proc_name_i VARCHAR2,p_anydata_map ANYDATA_MAP_T) RETURN VARCHAR2 IS
/* CURSOR v_arg_cur IS SELECT * FROM USER_ARGUMENTS
                    WHERE package_name =  upper(p_pkg_name_i)
                         AND object_name = upper(p_proc_name_i)
                    ORDER BY POSITION ;
                    */
v_ret_text VARCHAR2(32000);                    

v_data_type VARCHAR2(30);
v_arg_cur_t argument_curtype;
v_arg_rec USER_ARGUMENTS%ROWTYPE;
BEGIN

  v_ret_text := GET_DECLARE_BLOCK(p_anydata_map.get_data_list());
  
  v_arg_cur_t := GET_PKG_PROC_ARG_CURSOR(p_pkg_name_i, p_proc_name_i);
  
  LOOP
   FETCH v_arg_cur_t INTO v_arg_rec;
   EXIT WHEN v_arg_cur_t%NOTFOUND;
   v_data_type := v_arg_rec.DATA_TYPE;
   IF v_data_type  IN ('VARCHAR2','VARCHAR') THEN
      v_data_type := v_data_type || '(32667)' ;
   END IF;
   IF  not p_anydata_map.name_exists(lower(v_arg_rec.ARGUMENT_NAME)) then
      v_ret_text :=  v_ret_text ||  v_arg_rec.ARGUMENT_NAME || ' ' || v_data_type || ' := NULL;' || LF;
   END IF;  
   
  END LOOP;
  CLOSE v_arg_cur_t;
  
  /*
FOR rec IN v_arg_cur_t LOOP
 v_data_type := rec.DATA_TYPE;
 IF v_data_type  IN ('VARCHAR2','VARCHAR') THEN
    v_data_type := v_data_type || '(32667)' ;
 END IF;
 IF  not p_anydata_map.name_exists(lower(rec.ARGUMENT_NAME)) then
    v_ret_text :=  v_ret_text ||  rec.ARGUMENT_NAME || ' ' || v_data_type || ' := NULL;' || LF;
 END IF;  
 
END loop;
 */
  -- declare 


 return v_ret_text;

END;


FUNCTION GET_DYNA_SQL_4_PROC(p_pkg_name_i VARCHAR2, p_proc_name_i VARCHAR2,p_anydata_map ANYDATA_MAP_T) RETURN CLOB  IS
v_sql CLOB;
v_src_list TEXT_LIST_T;
v_new_src_list TEXT_LIST_T :=TEXT_LIST_T();
v_src_translated_list TEXT_LIST_T;
v_line LINE_TEXT_T;
v_code_start_line INTEGER;
v_lf constant CHAR(1) := CHR(10);

BEGIN

 IF p_pkg_name_i IS NOT NULL THEN
  v_src_list := GET_PROC_SOURCE( p_pkg_name_i , p_proc_name_i);
 ELSE
  v_src_list := GET_PROC_SOURCE_PROC(p_proc_name_i);
 END IF;
  
  -- Gets the start line number;
  FOR i IN 1..v_src_list.COUNT LOOP
      v_line := v_src_list(i);
      IF  regexp_instr(v_line,'\w* *[IS|AS] *$',1,1,0,'in') > 0 THEN
        v_code_start_line := i;
       exit ;
      END IF;
  END LOOP;
  
  -- Puts the pure source in a new list;
  v_code_start_line := v_code_start_line + 1;
  ORAMARKER_LOG_PKG.info('source code start at line:' || v_code_start_line);
  ORAMARKER_LOG_PKG.info('Total lines found:' || (v_src_list.COUNT - v_code_start_line + 1));
  v_new_src_list.EXTEND(v_src_list.COUNT - v_code_start_line + 1);
  
  FOR i IN v_code_start_line ..v_src_list.COUNT LOOP
    v_new_src_list(i- v_code_start_line + 1) := v_src_list(i);
  END LOOP;
  
  -- Translate lines
  v_src_translated_list := translate_lines(v_new_src_list);
  
  -- build pl/sql block
  v_sql :=   'DECLARE' || LF;
  
  v_sql := v_sql ||  GET_DECLARE_BLOCK(p_pkg_name_i , p_proc_name_i,p_anydata_map);
  
  v_sql := v_sql ||    'v_ret_text CLOB;' || LF;
  
  FOR i IN 1..v_src_translated_list.COUNT LOOP
    v_line := v_src_translated_list(i);
    if v_line is NOT NULL  THEN --AND v_line <> 'NULL;'
      if  v_line <> 'NULL;' then
        v_sql := v_sql ||    v_line ;
      else
       v_sql := v_sql ||    v_line || LF;
      end if; 
    END IF;
  END LOOP;
  v_sql := v_sql ||    ':b_text_from_sql := v_ret_text;' || LF;
  v_sql := v_sql ||    'END;' || LF;
RETURN v_sql;
END;




 PROCEDURE BIND_VARS(p_cursor_id BINARY_INTEGER,p_anydata_map ANYDATA_MAP_T) IS
       v_key VARCHAR2(200);
       v_value LINE_TEXT_T;
       v_data_list ANYDATA_LIST_T;
       v_anydata_t ANYDATA_T;
       v_datatype VARCHAR2(40);
       v_clob CLOB;
       
       v_anydata ANYDATA;
      BEGIN
        v_data_list := p_anydata_map.get_data_list();
      
        for i in 1..v_data_list.count LOOP
          v_anydata_t := v_data_list(i);
          v_key := v_anydata_t.name;
          v_anydata := v_anydata_t.data;
          v_datatype :=  SYS.ANYDATA.GETTYPENAME (v_anydata);
          -- bind variable
          ORAMARKER_LOG_PKG.info('Binding var:' || v_key);
          IF v_datatype = 'SYS.VARCHAR2' THEN
              dbms_sql.bind_variable(p_cursor_id, v_key, p_anydata_map.GET_VARCHAR2(v_key));
          ELSIF v_datatype = 'SYS.DATE' THEN
              dbms_sql.bind_variable(p_cursor_id, v_key, p_anydata_map.GET_DATE(v_key));
          ELSIF v_datatype = 'SYS.TIMESTAMP' THEN
              dbms_sql.bind_variable(p_cursor_id, v_key, p_anydata_map.GET_TIMESTAMP(v_key));
          ELSIF v_datatype = 'SYS.CLOB' THEN
              -- TODO 
               --p_anydata_map.GET_CLOB(v_key,v_clob);
              --dbms_sql.bind_variable(p_cursor_id, v_key,v_clob);
              null;
          ELSE
            RAISE_APPLICATION_ERROR(-20008, 'Data type not supported : ' || v_datatype);
              
          END IF;              
        END LOOP;
        
         
      END BIND_VARS;


PROCEDURE EVAl_SQL(p_sql VARCHAR2,p_anydata_map ANYDATA_MAP_T,p_clob_out OUT NOCOPY CLOB)  AS
      v_cursor_id BINARY_INTEGER;
      v_dummy  INTEGER;
      v_text_from_sql clob;
      v_pos INTEGER;
      v_char CHAR(1);
      
        e exception;
      pragma exception_init(e,-6550);
BEGIN
      v_cursor_id := dbms_sql.open_cursor;
      
      BEGIN
       dbms_sql.parse(v_cursor_id,p_sql,  dbms_sql.NATIVE);
        -- v_pos := DBMS_SQL.LAST_ERROR_POSITION;
         --ORAMARKER_LOG_PKG.INFO(' last error position :' || v_pos);
       EXCEPTION
         WHEN e THEN
         
         /*
           v_pos := DBMS_SQL.LAST_ERROR_POSITION;
          
          LOOP 
            v_char := SUBSTR(p_sql,v_pos,1);
            EXIT WHEN v_char = LF;
            v_pos := v_pos + 1;
            
          END LOOP;
          */
           
           ORAMARKER_LOG_PKG.INFO('Eror occured when parsing PL/SQL block:' || SQLERRM );
           RAISE;
      END; 
       
       bind_vars(v_cursor_id,p_anydata_map);
       dbms_sql.bind_variable(v_cursor_id, 'b_text_from_sql', p_clob_out);
        v_dummy := DBMS_SQL.EXECUTE(v_cursor_id);
        DBMS_SQL.VARIABLE_VALUE(v_cursor_id, 'b_text_from_sql', p_clob_out);
         dbms_sql.close_cursor(v_cursor_id);
END;

PROCEDURE MERGE_TEXT(p_template VARCHAR2,p_anydata_map ANYDATA_MAP_T,p_clob_out OUT NOCOPY CLOB)  IS
v_block_text VARCHAR2(32667);

v_data_list ANYDATA_LIST_T;
BEGIN
    v_data_list := p_anydata_map.get_data_list();
    v_block_text := ' DECLARE ' || LF;
    v_block_text := v_block_text ||  GET_DECLARE_BLOCK(v_data_list);
    v_block_text := v_block_text || ' v_ret_text VARCHAR2(32667); ' ||  LF;
    v_block_text := v_block_text || 'BEGIN' || LF;
    v_block_text := v_block_text || TRANSLATE_TEXT_LINE(p_template) || LF;
     v_block_text := v_block_text || ' :b_text_from_sql := v_ret_text; ' || LF;
    v_block_text := v_block_text || 'END;' || LF;
    ORAMARKER_LOG_PKG.INFO('PL/SQL BLOCK:' || LF || v_block_text);
     eval_sql(v_block_text,p_anydata_map,p_clob_out);

END MERGE_TEXT;

PROCEDURE COMPILE_TEMPLATE(p_proc_name VARCHAR2, p_target_proc_name VARCHAR2)  IS
BEGIN
NULL;
END COMPILE_TEMPLATE;

PROCEDURE COMPILE_TEMPLATE(p_pkg_name VARCHAR2,p_proc_name VARCHAR2, p_target_proc_name VARCHAR2)  IS
BEGIN
NULL;
END COMPILE_TEMPLATE;




PROCEDURE prv_GET_TEXT_FROM_PKG_PROC(p_pkg_name VARCHAR2,p_proc_name VARCHAR,p_anydata_map ANYDATA_MAP_T, p_clob_out OUT NOCOPY CLOB)  IS
  v_block_text CLOB;
BEGIN
  CHECK_BIND_VARS(p_pkg_name,p_proc_name,p_anydata_map);
  v_block_text := GET_DYNA_SQL_4_PROC(p_pkg_name,p_proc_name,p_anydata_map);
  --ORAMARKER_LOG_PKG.info(v_block_text);
  SHOW_SQL(v_block_text);
  eval_sql(v_block_text,p_anydata_map,p_clob_out);
END prv_GET_TEXT_FROM_PKG_PROC;  


PROCEDURE GET_TEXT_FROM_PROC(p_proc_name VARCHAR,p_anydata_map ANYDATA_MAP_T, p_clob_out OUT NOCOPY CLOB)  IS
BEGIN
prv_GET_TEXT_FROM_PKG_PROC(null, p_proc_name,p_anydata_map,p_clob_out);
END GET_TEXT_FROM_PROC;

PROCEDURE GET_TEXT_FROM_PKG_PROC(p_pkg_name VARCHAR2,p_proc_name VARCHAR,p_anydata_map ANYDATA_MAP_T, p_clob_out OUT NOCOPY CLOB)  IS
  v_block_text CLOB;
BEGIN
prv_GET_TEXT_FROM_PKG_PROC(p_pkg_name, p_proc_name,p_anydata_map,p_clob_out);
END GET_TEXT_FROM_PKG_PROC;

END ORAMARKER_PKG;

/