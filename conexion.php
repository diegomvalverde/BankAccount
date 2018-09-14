<!DOCTYPE html>
<html lang="en" dir="ltr">
  <head>
    <meta charset="utf-8">
    <title>"Página web BankAccount"</title>
  </head>
  <body>
    <form class="" action="conexion.php" method="post">
      <h4>Ingresar al sistema</h4>
      <h5>Ingresa tu identificación:</h5>
      <input type="text" name="id" value="" placeholder="604400430">
      <h5>Ingresa tu contraseña:</h5>
      <input type="text" name="contrasenna" value="" placeholder="JuanaDeArco">
      <button type="submit" name="consultarCliente" >Ingresar</button>
    </form>

    <form class="" action="conexion.php" method="post">
      <h4>Agregar cliente</h4>
      <h5>Identificación:</h5>
      <input type="text" name="id" value="" placeholder="604400433">
      <h5>Nombre:</h5>
      <input type="text" name="nombre" value="" placeholder="Diego Méndez">
      <h5>Contraseña:</h5>
      <input type="text" name="contrasenna" value="" placeholder="JuanaDeArco">
      <button type="submit" name="insertarCliente" >Ingresar</button>
    </form>

    <form class="" action="conexion.php" method="post">
      <h4>Agregar movimiento</h4>
      <h5>Código de cuenta:</h5>
      <input type="text" name="idCuenta" value="" placeholder="10092938726551678299">
      <h5>Tipo de Movimiento:</h5>
      <input type="text" name="tipoMovimiento" value="" placeholder="1">
      <h5>Monto:</h5>
      <input type="text" name="monto" value="" placeholder="1500">
      <button type="submit" name="insertarMovimiento" >Ingresar</button>
    </form>

    <form class="" action="conexion.php" method="post">
      <h4>Agregar cuenta</h4>
      <h5>Código de cuenta:<h5><input type="text" name="idCuenta" value="" placeholder="10092938726551678299">
      <h5>Tipo de cuenta:</h5>
      <input type="text" name="tipoCuenta" value="" placeholder="7">
      <h5>Identificación:</h5>
      <input type="text" name="idCliente" value="" placeholder="604400433">
      <button type="submit" name="insertarCuenta" >Ingresar</button>
    </form>

  </body>
</html>

<?php
if(isset($_POST["insertarMovimiento"]))
{
  $codCuenta = $_POST['idCuenta'];
  $tipoMovimiento = $_POST['tipoMivimiento'];
  $monto = $_POST['monto'];
  $posIp = "Desconocido";
  $resultado = insertarMovimiento($codCuenta, $monto, $tipoMovimiento, $posIp);
}
if(isset($_POST["insertarCliente"]))
{
  $valorDocID = $_POST['id'];
  $nombre = $_POST['nombre'];
  $contrasenna = $_POST['contrasenna'];
  $resultado = insertarCliente($valorDocID, $nombre, $contrasenna)
}
if(isset($_POST["insertarCuenta"]))
{
  $idCuenta = $_POST['idCuenta'];
  $tipoCuenta = $_POST['tipoCuenta'];
  $idCliente = $_POST['idCliente'];
  $resultado = insertarCuenta($idCliente, $tipoCuenta, $idCuenta);
}
if(isset($_POST["consultarCliente"]))
{
  $valorDocID = $_POST['id'];
  $contrasenna = $_POST['contrasenna'];
  $resultado = consultarUsuario($valorDocID, $contrasenna);
}
// Funciones para llamar a procedimoento almacenados

function insertarCliente($param1, $param2, $param3)
{
  $servername = 'DESKTOP-LFI86EI\SQLEXPRESS';
  $conectionInfo = array("Database"=>'BankAccount', "UID"=>"user", "PWD"=>"userpass", "CharacterSet"=>"UTF-8");
  $conn_sis = sqlsrv_connect($servername, $conectionInfo);

  if($conn_sis)
  {
    echo "Coneccion exitosa";
  }
  else
  {
      die(print_r(sqlsrv_errors(), true));
  }

  $sql = "{call casp_agregarcliente(?,?,?)}";

  $params = array
  (
  array($param1,SQLSRV_PARAM_IN),
  array($param2, SQLSRV_PARAM_IN),
  array($param3, SQLSRV_PARAM_IN)
  );

  $stmt = sqlsrv_query($conn_sis, $sql, $params) or die(print_r(sqlsrv_errors(),true));


  if( $stmt === false )
  {
  // echo "Error in executing statement 3.\n";
  die( print_r( sqlsrv_errors(), true));
  }
  return $stmt;
}


function consultarUsuario($param1, $param2)
{
  $servername = 'DESKTOP-LFI86EI\SQLEXPRESS';
  $conectionInfo = array("Database"=>'BankAccount', "UID"=>"user", "PWD"=>"userpass", "CharacterSet"=>"UTF-8");
  $conn_sis = sqlsrv_connect($servername, $conectionInfo);

  if($conn_sis)
  {
    echo "Coneccion exitosa";
  }
  else
  {
      die(print_r(sqlsrv_errors(), true));
  }
  $sql = "{call casp_consultausuario(?,?)}";
  $params = array
  (
  array($param1,SQLSRV_PARAM_IN),
  array($param2, SQLSRV_PARAM_IN)
  );

  $stmt = sqlsrv_query($conn_sis, $sql, $params) or die(print_r(sqlsrv_errors(),true));


  if( $stmt === false )
  {
  // echo "Error in executing statement 3.\n";
  die( print_r( sqlsrv_errors(), true));
  }
  echo sqlsrv_fetch_array($stmt)[0];
}

function agregarMovimiento($param1, $param2, $param3, $param4 )
{
  $servername = 'DESKTOP-LFI86EI\SQLEXPRESS';
  $conectionInfo = array("Database"=>'BankAccount', "UID"=>"user", "PWD"=>"userpass", "CharacterSet"=>"UTF-8");
  $conn_sis = sqlsrv_connect($servername, $conectionInfo);

  if($conn_sis)
  {
    echo "Coneccion exitosa";
  }
  else
  {
      die(print_r(sqlsrv_errors(), true));
  }
  $sql = "{call casp_movimiento(?,?,?,?)}";
  $params = array
  (
  array($param1,SQLSRV_PARAM_IN),
  array($param2, SQLSRV_PARAM_IN),
  array($param3, SQLSRV_PARAM_IN),
  array($param4, SQLSRV_PARAM_IN)
  );

  $stmt = sqlsrv_query($conn_sis, $sql, $params) or die(print_r(sqlsrv_errors(),true));


  if( $stmt === false )
  {
  // echo "Error in executing statement 3.\n";
  die( print_r( sqlsrv_errors(), true));
  }
  echo sqlsrv_fetch_array($stmt)[0];
}

function insertarCuenta($param1, $param2, $param3)
{
  $servername = 'DESKTOP-LFI86EI\SQLEXPRESS';
  $conectionInfo = array("Database"=>'BankAccount', "UID"=>"user", "PWD"=>"userpass", "CharacterSet"=>"UTF-8");
  $conn_sis = sqlsrv_connect($servername, $conectionInfo);

  if($conn_sis)
  {
    echo "Coneccion exitosa";
  }
  else
  {
      die(print_r(sqlsrv_errors(), true));
  }

  $sql = "{call casp_agregarcuenta(?,?,?)}";

  $params = array
  (
  array($param1,SQLSRV_PARAM_IN),
  array($param2, SQLSRV_PARAM_IN),
  array($param3, SQLSRV_PARAM_IN)
  );

  $stmt = sqlsrv_query($conn_sis, $sql, $params) or die(print_r(sqlsrv_errors(),true));


  if( $stmt === false )
  {
  // echo "Error in executing statement 3.\n";
  die( print_r( sqlsrv_errors(), true));
  }
  return $stmt;
}


?>
