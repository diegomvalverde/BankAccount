/*
Script para la simulación de entrada de grands cantidades de datos, los datos
se leen de un xml.
*/
use BankAccount
go


/*
Variables para los xml
*/

declare @xmlCliente xml
set @XMLCliente = 
(
	select * from openrowset(bulk 'C:\Bases\Administrador.xml', single_blob) as data
)

declare @xmlAdmin xml
set @xmlAdmin = 
(
	select * from openrowset(bulk 'C:\Bases\Administrador.xml', single_blob) as data
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


/*
Creacion de las tablas temporales
*/

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

declare @TiposCuentaCrear table
(
	nombre nvarchar(50),
	tasaInteres float,
	saldoMin money,
	cantMaxMAnual int,
	cantMaxATM int,
	multaSaldoMin money,
	multaCantMaxManual money,
	multaCantmaxATM money,
	mulaSaldoNegativo money,
	cargoServicio money,
	id int
)

declare @TipoEventoCrear table
(
	descripcion nvarchar(70),
	nombre nvarchar(50),
	id int
)

declare @TipoMovimientoCrear table
(
	nombre nvarchar(100),
	id int, 
	descripcion nvarchar(200)
)

declare @TipoMovInteresCrear table
(
	nombre nvarchar(50),
	descripcion nvarchar(70),
	id int
)

/*
Cargar los administradores del xml
*/ 

exec @PrepareXmlStatus= sp_xml_preparedocument @handle output, @xmlAdmin  

insert @AdminsCrear(nombre, idAdmin, contrasenna)
		select nombre, valorDocId, contrasenna
		from openxml(@handle, '/dataset/Administrador') with (nombre nvarchar(50), valorDocId nvarchar(50), contrasenna nvarchar(50));

/*
Cargar los tipos de cuenta del xml
*/

exec @PrepareXmlStatus= sp_xml_preparedocument @handle output, @xmlTipoCuenta

insert @TiposCuentaCrear(id, cargoServicio, mulaSaldoNegativo, multaCantmaxATM, multaCantMaxManual, multaSaldoMin, cantMaxATM, cantMaxMAnual,
					saldoMin, tasaInteres, nombre)

		select id, cargoXservicio, multaSaldoNegativo, multaQMaxATM, multaQMaxManual, multaSaldoMinimo, QMaxATM, QMaxManual, saldoMinimo, 
				tasaInteres, nombre
		from openxml(@handle, '/dataset/TipoCuenta') with (id int, cargoXservicio money, multaSaldoNegativo money, multaQMaxATM money, 
															multaQMaxManual money, multaSaldoMinimo money, QMaxATM int, QMaxManual int, 
															saldoMinimo money, tasaInteres int, nombre nvarchar(50));

/*
Cargar los tipos de evento del xml
*/ 

exec @PrepareXmlStatus= sp_xml_preparedocument @handle output, @xmlTipoEvento 

insert @TipoEventoCrear(id, nombre, descripcion)
		select id, nombre, descripcion
		from openxml(@handle, '/dataset/TipoEvento') with (id int, nombre nvarchar(50), descripcion nvarchar(70));

/*
Cargar los tipos de movimientos del xml
*/ 

exec @PrepareXmlStatus= sp_xml_preparedocument @handle output, @xmlTipoMovimiento 

insert @TipoMovimientoCrear(id, nombre, descripcion)
		select id, nombre, descripcion
		from openxml(@handle, '/dataset/TipoMovimiento') with (id int, nombre nvarchar(100), descripcion nvarchar(200));

/*
Cargar los tipos de movimientos interes del xml
*/ 

exec @PrepareXmlStatus= sp_xml_preparedocument @handle output, @XMLTipoMovimientoInteres

insert @TipoMovInteresCrear(id, nombre, descripcion)
		select id, nombre, descripcion
		from openxml(@handle, '/dataset/TipoMovimientoInteres') with (id int, nombre nvarchar(50), descripcion nvarchar(70));
    

/* 
While para mapear el XML por fechas ya agregar los movimientos a las tablas
*/

while @fechaIncio <= @fechaFinal
	begin
		delete ;

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


	use master
	go