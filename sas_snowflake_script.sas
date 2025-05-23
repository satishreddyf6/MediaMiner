%macro load_csv_to_snowflake(csv_path=, sf_table=);

    /* Step 1: Import CSV */
    proc import datafile="&csv_path"
        out=work.imported_data
        dbms=csv
        replace;
        guessingrows=MAX;
    run;

    /* Step 2: Create a temp table in Snowflake using your macro connection */
    proc sql;
        %connectsflk;

        /* Optional: drop table if exists */
        execute (drop table if exists &sf_table) by mycon;

        /* Create table manually or let PROC APPEND handle it */
        disconnect from mycon;
    quit;



    /* Step 3: Insert data using passthrough INSERT INTO ... SELECT * FROM local SAS dataset */
    proc sql;
        %connectsflk;
        insert into mycon.&sf_table
        select * from work.imported_data;
        disconnect from mycon;
    quit;
    
    /* Step 3: Use PROC APPEND or explicit upload via FEDSQL */
    libname snowflake sasiosnf dsn='snowflake_dsn' user='your_user' password='your_pass';

    proc append base=snowflake.&sf_table (bulkload=yes bl_options="OVERWRITE=YES") 
        data=work.imported_data force;
    run;

    libname snowflake clear;

%mend;
