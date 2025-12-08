show con_name;
 --change container to default CDB$ROOT
alter session set container = cdb$root;
 --crate a pluggable database
create pluggable database freepdb2
   admin user pdb2admin identified by oracle
      file_name_convert = ( '/opt/oracle/oradata/FREE/pdbseed','/opt/oracle/oradata/FREE/FREEPDB2' );
 --activatethe databse 
alter session set container = freepdb2;
alter database open read write;


show pdbs;