<?php
header('Access-Control-Allow-Origin: *');
// Check if the form is submitted Chequear si el post fue hecho
$usuario = $_POST['usr'];
$contra  = $_POST['pwd'];

if($usuario != null and $contra != null)
{
  echo consultarUsuario($usuario, $contra);
}

// Funciones para llamar a procedimoento almacenados
//
// function insertarCliente($param1, $param2, $param3)
// {
//   $servername = 'DESKTOP-LFI86EI\SQLEXPRESS';
//   $conectionInfo = array("Database"=>'BankAccount', "UID"=>"user", "PWD"=>"userpass", "CharacterSet"=>"UTF-8");
//   $conn_sis = sqlsrv_connect($servername, $conectionInfo);
//
//   if($conn_sis)
//   {
//     echo "Coneccion exitosa";
//   }
//   else
//   {
//       die(print_r(sqlsrv_errors(), true));
//   }
//
//   $sql = "{call casp_agregarcliente(?,?,?)}";
//
//   $params = array
//   (
//   array($param1,SQLSRV_PARAM_IN),
//   array($param2, SQLSRV_PARAM_IN),
//   array($param3, SQLSRV_PARAM_IN)
//   );
//
//   $stmt = sqlsrv_query($conn_sis, $sql, $params) or die(print_r(sqlsrv_errors(),true));
//
//
//   if( $stmt === false )
//   {
//   // echo "Error in executing statement 3.\n";
//   die( print_r( sqlsrv_errors(), true));
//   }
//   return $stmt;
// }
//

// Funcion para consultar clientes en la base de datos.
function consultarUsuario($param1, $param2)
{
  $servername = 'DESKTOP-LFI86EI\SQLEXPRESS';
  $conectionInfo = array("Database"=>'BankAccount', "UID"=>"user", "PWD"=>"userpass", "CharacterSet"=>"UTF-8");
  $conn_sis = sqlsrv_connect($servername, $conectionInfo);

  if($conn_sis)
  {
    // echo "Conexion exitosa";
  }
  else
  {
      die(print_r(sqlsrv_errors(), true));
  }

  $outSeq=-1;
  $sql = "{call casp_consultausuario(?,?,?)}";
  $params = array
  (
  array($param1,SQLSRV_PARAM_IN),
  array($param2, SQLSRV_PARAM_IN),
  array(&$outSeq, SQLSRV_PARAM_INOUT)
  );

  $stmt = sqlsrv_query($conn_sis, $sql, $params) or die(print_r(sqlsrv_errors(),true));

  if( $stmt === false )
  {
  // echo "Error in executing statement 3.\n";
  die( print_r( sqlsrv_errors(), true));
  }

  sqlsrv_next_result($stmt);
  sqlsrv_close($conn_sis);
  return $outSeq;

}

// function agregarMovimiento($param1, $param2, $param3, $param4 )
// {
//   $servername = 'DESKTOP-LFI86EI\SQLEXPRESS';
//   $conectionInfo = array("Database"=>'BankAccount', "UID"=>"user", "PWD"=>"userpass", "CharacterSet"=>"UTF-8");
//   $conn_sis = sqlsrv_connect($servername, $conectionInfo);
//
//   if($conn_sis)
//   {
//     echo "Coneccion exitosa";
//   }
//   else
//   {
//       die(print_r(sqlsrv_errors(), true));
//   }
//   $sql = "{call casp_movimiento(?,?,?,?)}";
//   $params = array
//   (
//   array($param1,SQLSRV_PARAM_IN),
//   array($param2, SQLSRV_PARAM_IN),
//   array($param3, SQLSRV_PARAM_IN),
//   array($param4, SQLSRV_PARAM_IN)
//   );
//
//   $stmt = sqlsrv_query($conn_sis, $sql, $params) or die(print_r(sqlsrv_errors(),true));
//
//
//   if( $stmt === false )
//   {
//   // echo "Error in executing statement 3.\n";
//   die( print_r( sqlsrv_errors(), true));
//   }
//   return sqlsrv_fetch_array($stmt)[0];
// }
//
// function insertarCuenta($param1, $param2, $param3)
// {
//   $servername = 'DESKTOP-LFI86EI\SQLEXPRESS';
//   $conectionInfo = array("Database"=>'BankAccount', "UID"=>"user", "PWD"=>"userpass", "CharacterSet"=>"UTF-8");
//   $conn_sis = sqlsrv_connect($servername, $conectionInfo);
//
//   if($conn_sis)
//   {
//     echo "Coneccion exitosa";
//   }
//   else
//   {
//       die(print_r(sqlsrv_errors(), true));
//   }
//
//   $sql = "{call casp_agregarcuenta(?,?,?)}";
//
//   $params = array
//   (
//   array($param1,SQLSRV_PARAM_IN),
//   array($param2, SQLSRV_PARAM_IN),
//   array($param3, SQLSRV_PARAM_IN)
//   );
//
//   $stmt = sqlsrv_query($conn_sis, $sql, $params) or die(print_r(sqlsrv_errors(),true));
//
//
//   if( $stmt === false )
//   {
//   // echo "Error in executing statement 3.\n";
//   die( print_r( sqlsrv_errors(), true));
//   }
//   return $stmt;
// }


?>
