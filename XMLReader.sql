/*
Script para la simulación de entrada de grands cantidades de datos, los datos
se leen de un xml.
*/
use BankAccount
go


/*
Variables para los xml
*/

declare @xmlOps xml
select @xmlOps = BulkColumn
from openrowset(bulk 'C:\Bases\Operaciones.xml', single_blob) x


declare @xmlAdmin xml
set @xmlAdmin = 
(
	select * from openrowset(bulk 'C:\Bases\Administrador.xml', single_blob) as x
);


declare @xmlTipoCuenta xml
set @xmlTipoCuenta = 
(
	select * from openrowset(bulk 'C:\Bases\TipoCuenta.xml', single_blob) as x
);

declare @xmlTipoEvento xml
set @xmlTipoEvento = 
(
	select * from openrowset(bulk 'C:\Bases\TipoEvento.xml', single_blob) as x
);

declare @xmlTipoMovimiento xml
set @xmlTipoMovimiento = 
(
	select * from openrowset(bulk 'C:\Bases\TipoMovimiento.xml', single_blob) as x
);

declare @xmlTipoMovimientoInteres xml
set @xmlTipoMovimientoInteres = 
(
	select * from openrowset(bulk 'C:\Bases\TipoMovimientoInteres.xml', single_blob) as x
);

declare @handle int;  
declare @PrepareXmlStatus int;  
declare @fechaIncio int;
declare @fechaFinal int;
declare @minSec int = 0;
declare @maxSec int = 0;


/*
Creacion de las tablas temporales
*/

declare @ClientesCrear table 
(
	sec int identity(1,1),
	docId nvarchar(10),
	nombre nvarchar(50),
	contrasenna nvarchar(50)
);

declare @CuentasCrear table
(
	sec int identity(1,1),
	idCliente nvarchar(50),
	tipoCuenta int,
	fechaCreacion date,
	saldo money
);

declare @AdminsCrear table
(
	sec int identity(1,1),
	idAdmin nvarchar(50),
	contrasenna nvarchar(50),
	nombre nvarchar(50)
);

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
);

declare @TipoEventoCrear table
(
	descripcion nvarchar(70),
	nombre nvarchar(50),
	id int
);

declare @TipoMovimientoCrear table
(
	nombre nvarchar(100),
	id int, 
	descripcion nvarchar(200)
);

declare @TipoMovInteresCrear table
(
	nombre nvarchar(50),
	descripcion nvarchar(70),
	id int
);

declare @Fechas table
(
	id int identity(1,1),
	fecha date 
);

/*
Cargar los administradores del xml
*/ 

exec @PrepareXmlStatus= sp_xml_preparedocument @handle output, @xmlAdmin ; 

insert @AdminsCrear(nombre, idAdmin, contrasenna)
		select nombre, valorDocId, contrasenna
		from openxml(@handle, '/dataset/Administrador') with (nombre nvarchar(50), valorDocId nvarchar(50), contrasenna nvarchar(50));

/*
Cargar los tipos de cuenta del xml
*/

exec @PrepareXmlStatus= sp_xml_preparedocument @handle output, @xmlTipoCuenta;

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

exec @PrepareXmlStatus= sp_xml_preparedocument @handle output, @xmlTipoEvento;

insert @TipoEventoCrear(id, nombre, descripcion)
		select id, nombre, descripcion
		from openxml(@handle, '/dataset/TipoEvento') with (id int, nombre nvarchar(50), descripcion nvarchar(70));

/*
Cargar los tipos de movimientos del xml
*/ 

exec @PrepareXmlStatus= sp_xml_preparedocument @handle output, @xmlTipoMovimiento ;

insert @TipoMovimientoCrear(id, nombre, descripcion)
		select id, nombre, descripcion
		from openxml(@handle, '/dataset/TipoMovimiento') with (id int, nombre nvarchar(100), descripcion nvarchar(200));

/*
Cargar los tipos de movimientos interes del xml
*/ 

exec @PrepareXmlStatus= sp_xml_preparedocument @handle output, @XMLTipoMovimientoInteres;

insert @TipoMovInteresCrear(id, nombre, descripcion)
		select id, nombre, descripcion
		from openxml(@handle, '/dataset/TipoMovimientoInteres') with (id int, nombre nvarchar(50), descripcion nvarchar(70));

/*
Cargar todas las fechas del xml en una tabla para recorrerlas
*/ 

exec @PrepareXmlStatus= sp_xml_preparedocument @handle output, @xmlOps;

insert @Fechas(fecha)
		select fecha
		from openxml(@handle, '/dataset/fechaOperacion') with (fecha date);
    
/* 
While para mapear el XML por fechas ya agregar los movimientos a las tablas
*/

set @fechaIncio = 1;
select @fechaFinal = max(id) from @fechas;
declare @fechaOperacion date;
declare @low1 int;
declare @hi1 int;
declare @valorDocId nvarchar(50);
declare @nombre nvarchar(50);
declare @contrasenna nvarchar(50);



print '____________________________________' ;
while @fechaIncio <= @fechaFinal
	begin
		delete @ClientesCrear;

		/*
		Se guarda la fecha en @fechaOperacion para s'olo guardar los movimientos de una fecha por vez 
		*/

		select @fechaOperacion = F.fecha 
			from @fechas F 
			where @fechaIncio = F.id;

		/*
		Insercion de las cuentas en la tabla temporal
		*/
		exec @PrepareXmlStatus= sp_xml_preparedocument @handle output, @xmlOps;

		insert @ClientesCrear(nombre, docId, contrasenna)
			select nombre, valorDocId, contrasenna 
			from openxml(@handle, '/dataset/fechaOperacion/Cliente') with (nombre nvarchar(50), valorDocId nvarchar(50), contrasenna nvarchar(50))
			where @xmlOps.value('(/dataset/fechaOperacion/@fecha)[1]', 'date')  = @fechaOperacion;

		print @fechaOperacion

		select @low1 = min(C.sec) from @ClientesCrear C;
		select @hi1 = max(C.sec) from @ClientesCrear C;


		/*
		Insertar los clientes temporales en las tablas de la base de datos
		*/

		while @low1 <= @hi1
			begin
				select @valorDocId = C.docId, @nombre = C.nombre, @contrasenna = C.contrasenna 
					from @ClientesCrear C
					where C.sec = @low1;
				insert into Cliente(nombre, valorDocId, contrasenna, visible)
					values(@nombre, @valorDocId, @contrasenna, 1);

				set @low1 = @low1 + 1;
			end

		--// select @minSec = min(sec); Qué es sec?
		
		set @fechaIncio = @fechaIncio + 1;
	end;


	use master
	go