/*
Script para la simulación de entrada de grands cantidades de datos, los datos
se leen de un xml.
*/

use BankAccount
go

create procedure xmlreader
as
begin

declare @xmlCliente xml
set @XMLCliente = 
(
	select * from openrowset(bulk 'C:\Bases\Clientes.xml', single_blob) as data
)

declare @xmlAdmin xml
set @xmlAdmin = 
(
	select * from openrowset(bulk 'C:\Bases\Administrador.xml', single_blob) as data
)

declare @xmlOperaciones xml
set @xmlOperaciones = 
(
	select * from openrowset(bulk 'C:\Bases\Operaciones.xml', single_blob) as data
)

declare @xmlTipoCuenta xml
set @xmlTipoCuenta = 
(
	select * from openrowset(bulk 'C:\Bases\TipoCuenta.xml', single_blob) as data
)

declare @xmlTipoEvento xml
set @xmlTipoEvento = 
(
	select * from openrowset(bulk 'C:\Bases\TipoEvento.xml', single_blob) as data
)

declare @xmlTipoMovimiento xml
set @xmlTipoMovimiento = 
(
	select * from openrowset(bulk 'C:\Bases\TipoMovimiento.xml', single_blob) as data
)

declare @XMLTipoMovimientoInteres xml
set @XMLTipoMovimientoInteres = 
(
	select * from openrowset(bulk 'C:\Bases\TipoMovimientoInteres.xml', single_blob) as data
)

declare @handle int;  
declare @PrepareXmlStatus int;  
declare @fechaIncio int = 0;
declare @fechaFinal int = 10;
declare @minSec int = 0;
declare @maxSec int = 0;

exec @PrepareXmlStatus= sp_xml_preparedocument @handle output, @xmlCliente

declare @ClientesCrear table 
(
	sec int identity(1,1),
	docId nvarchar(10),
	nombre nvarchar(50)
)

declare @CuentasCrear table
(
	sec int identity(1,1),
	idCliente nvarchar(50),
	tipoCuenta int,
	fechaCreacion date,
	saldo money
)

declare @AdminsCrear table
(
	sec int identity(1,1),
	idAdmin nvarchar(50),
	contrasenna nvarchar(50),
	nombre nvarchar(50)
)



/*
Creacion de los asministradores
*/

insert @AdminsCrear (idAdmin, nombre, contrasenna)
		select valorDocId, nombre
		from openxml(@handle, 'dataset/Administrador') with (valorDocId nvarchar, nombre nvarchar(50));

/* 
While para mapear el XML por fechas ya agregar los movimientos a las tablas
*/

while @fechaIncio <= @fechaFinal
	begin
		delete @ClientesCrear;

		/* 
		Insercion de los clientes en la tabla temporal
		*/

		insert @ClientesCrear (docId, nombre)
		select docId, nombre
		from openxml(@handle, 'dataset/Cliente') with (docId int, nombre nvarchar(50));

		/*
		Insercion de las cuentas en la tabla temporal
		*/

		insert @CuentasCrear (idCliente, tipoCuenta, fechaCreacion, saldo)
		select idCliente, tipoCuenta, fechacreacion, sado
		from openxml(@handle, 'dateset/Cuenta') with (idCliente nvarchar(50), tipoCuenta int, 
		fechaCreacion date, saldo money);

		--// select @minSec = min(sec); Qué es sec?
		set @fechaIncio = @fechaIncio + 1;
	end;

	end

go
use master
go