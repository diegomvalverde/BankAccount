/*
Script para la simulación de entrada de grands cantidades de datos, los datos
se leen de un xml.
*/
use BankAccount
go

set dateformat dmy;  
go  

/*
Variables para los xml
*/

declare @xmlOps xml
set @xmlOps = 
(
	select * from openrowset(bulk 'C:\Bases\Operaciones_v2.xml', single_blob) as x
);


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
	id int identity(1,1),
	idCliente nvarchar(50),
	tipoCuenta int,
	codigoCuenta nvarchar(100)
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
	id int,
	sec int identity(1,1)
);

declare @TipoEventoCrear table
(
	descripcion nvarchar(70),
	nombre nvarchar(50),
	id int,
	sec int identity(1,1)
);

declare @TipoMovimientoCrear table
(
	nombre nvarchar(50),
	id int, 
	descripcion nvarchar(200),
	sec int identity(1,1)
);

declare @TipoMovInteresCrear table
(
	nombre nvarchar(50),
	descripcion nvarchar(70),
	id int,
	sec int identity(1,1)
);

declare @movimientosCrear table
(
	id int,
	monto money,
	tipoMovimiento int,
	codigoCuenta_Movimiento nvarchar(100),
	descripcion nvarchar(200),
	sec int identity(1,1)
)

declare @Fechas table
(
	id int identity(1,1),
	fecha date 
);


--select convert (varchar, F.fecha, 105) from @Fechas F



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
		from openxml(@handle, '/dataset/TipoMovimiento') with (id int, nombre nvarchar(50), descripcion nvarchar(200));

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

select * from @Fechas;

set @fechaIncio = 1;
select @fechaFinal = max(F.id) 
	from @fechas F;
print @fechaFinal;
declare @fechaOperacion date;
declare @fechaEstadoCuenta date;
declare @low1 int;
declare @hi1 int;
declare @valorDocId nvarchar(50);
declare @nombre nvarchar(50);
declare @contrasenna nvarchar(50);
declare @idCuenta nvarchar(50);
declare @tipoCuenta int;
declare @tiempo time;
declare @monto money;
declare @tipoMovimiento int;

/*
Agregar los tipos de movimientos interes temporales a la tabla de la base de datos
*/ 

select @low1 = min(T.sec) from @TipoMovInteresCrear T;
select @hi1 = max(T.sec) from @TiposCuentaCrear T;

while @low1 <= @hi1
	begin
		insert into TipoMovInteres(id, nombre, descripcion)
			select T.id, T.nombre, T.descripcion
			from @TipoMovInteresCrear T
			where T.id = @low1;

		set @low1 = @low1 + 1;
	end

/*
Agregar los tipos de cuanta a as tablas de la base de datos
*/

select @low1 = min(T.sec) from @TiposCuentaCrear T;
select @hi1 = max(T.sec) from @TiposCuentaCrear T;

while @low1 <= @hi1
	begin
		insert into TipoCuenta(id, cantMaxATM, cantMaxMAnual, cargoServicio, mulaSaldoNegativo, multaCantmaxATM, 
			multaCantMaxManual, multaSaldoMin, nombre, saldoMin, tasaInteres)
			select T.id, T.cantMaxATM, T.cantMaxMAnual, T.cargoServicio, T.mulaSaldoNegativo, T.multaCantmaxATM,
					T.multaCantMaxManual, T.multaSaldoMin, T.nombre, T.saldoMin, T.tasaInteres 
			from @TiposCuentaCrear T
			where T.id = @low1;

		set @low1 = @low1 + 1;
	end

/*
Guardar los Administradores de la tabla temporal en la tabla de la base de datos.
*/ 

select @low1 = min(A.sec) from @AdminsCrear A;
select @hi1 = max(A.sec) from @AdminsCrear A;

while @low1 <= @hi1
	begin
		insert into Administrador(nombre, valorDocId, contrasenna)
			select A.nombre, A.idAdmin, A.contrasenna
			from @AdminsCrear A
			where A.sec = @low1;

		set @low1 = @low1 + 1;
	end


/*
Cargar los tipos de evento de la tabla temporal en la tabla de la base de datos.
*/ 

select @low1 = min(T.sec) from @TipoEventoCrear T;
select @hi1 = max(T.sec) from @TipoEventoCrear T;

while @low1 <= @hi1
	begin
		insert into TipoEvento(id, nombre, descripcion)
			select T.id, T.nombre, T.descripcion
			from @TipoEventoCrear T
			where T.id = @low1;

		set @low1 = @low1 + 1;
	end

/*
Cargar los tipos de movimientos de la tabla temporal en la tabla de la base de datos.
*/ 

select @low1 = min(T.sec) from @TipoMovimientoCrear T;
select @hi1 = max(T.sec) from @TipoMovimientoCrear T;

while @low1 <= @hi1
	begin
		insert into TipoMovimiento(id, nombre, descripcion)
			select T.id, T.nombre, T.descripcion
			from @TipoMovimientoCrear T
			where T.id = @low1;

		set @low1 = @low1 + 1;
	end

/*
Recorrido del xml de operaciones por fecha para crear clientes, movimientos y cuentas.
*/

set @fechaIncio = 0;
select @fechaFinal = max(F.id)
	from @Fechas F;
while @fechaIncio <= @fechaFinal
	begin
		delete @ClientesCrear;
		delete @CuentasCrear;
		delete @movimientosCrear;

		/*
		Se guarda la fecha en @fechaOperacion para sólo guardar los movimientos de una fecha por vez 
		*/
		set @fechaIncio = @fechaIncio + 1;

		select @fechaOperacion = F.fecha
			from @Fechas F
			where F.id = @fechaIncio;

		print @fechaOperacion;
		/*
		Insercion de las cuentas en la tabla temporal de clientes
		*/
		exec @PrepareXmlStatus= sp_xml_preparedocument @handle output, @xmlOps;

		insert @ClientesCrear(nombre, docId, contrasenna)
			select nombre, valorDocId, contrasenna 
			from openxml(@handle, '/dataset/fechaOperacion/Cliente') with (nombre nvarchar(50), valorDocId nvarchar(50), contrasenna nvarchar(100))
			where @xmlOps.value('(/dataset/fechaOperacion/@fecha)[1]', 'date') = @fechaOperacion;

		select @low1 = 1;
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

		/*
		Insercion de las cuantas en las tablas temporales de cuentas.
		*/
		insert @CuentasCrear(idCliente, tipoCuenta, codigoCuenta)
			select docIdCliente, tipoCuenta, codigoCuenta
			from openxml(@handle, '/dataset/fechaOperacion/Cuenta') with (docIdCliente nvarchar(50), tipoCuenta int, codigoCuenta nvarchar(50))
			where @xmlOps.value('(/dataset/fechaOperacion/@fecha)[1]', 'date')  = @fechaOperacion;

		select @low1 = 1;
		select @hi1 = max(C.id) from @CuentasCrear C;


		/*
		Insertar las cuentas temporales en las tablas de la base de datos
		*/

		while @low1 <= @hi1
			begin
				select @valorDocId = C.idCliente, @tipoCuenta = C.tipoCuenta, @idCuenta = C.codigoCuenta 
					from @CuentasCrear C
					where C.id = @low1;

				insert into Cuenta(fechaCreacion, idCliente, idTipoCuenta, interesesAcumulados, saldo, codigoCuenta)
					select @fechaOperacion, C.id, F.id, 0.00, 0.00, @idCuenta
					from Cliente C, TipoCuenta F
					where C.valorDocId = @valorDocId and F.id = @tipoCuenta;

				insert into EstadoCuenta(idCuenta, nombre, saldoInicial, saldoFinal, fechaInicial, fechaFinal, cantmMaxATM, cantMaxManual, enProceso, saldoMinimo)
					select C.idCliente, 'Estado de cuenta del: ', C.saldo, C.saldo, @fechaOperacion, @fechaOperacion, 0, 0, 1, C.saldo
					from Cuenta C
					where C.id = @low1;

				set @low1 = @low1 + 1;
			end


		/*
		Insercion de los movimientos en la tabla temporal de movimientos.
		*/

		insert @movimientosCrear(monto, tipoMovimiento, codigoCuenta_Movimiento, descripcion)
			select monto, tipoMovimiento, codigoCuenta_Movimiento, descripcion
			from openxml(@handle, '/dataset/fechaOperacion/Movimiento') with (monto money, tipoMovimiento int, codigoCuenta_Movimiento nvarchar(100),
																		 descripcion nvarchar(200))
			where @xmlOps.value('(/dataset/fechaOperacion/@fecha)[1]', 'date')  = @fechaOperacion;

		select @low1 = 1;
		select @hi1 = max(M.sec) from @movimientosCrear M;


		/*
		Insertar los movimientos temporales en las tablas de la base de datos
		*/

		while @low1 <= @hi1
			begin

				select @tiempo = convert(varchar(10), GETDATE(), 108)

				select @tipoCuenta = C.id, @tipoMovimiento = M.tipoMovimiento
					from Cuenta C, @movimientosCrear M
					where C.codigoCuenta = M.codigoCuenta_Movimiento and M.sec = @low1;

				insert into Movimiento(fecha, idMovimiento, idTipoMovimiento, invisible, postIp, postTime, monto)
					select @fechaOperacion, C.id, M.tipoMovimiento, 0, 'Unknown', @tiempo, M.monto
					from Cuenta C, @movimientosCrear M
					where C.codigoCuenta = M.codigoCuenta_Movimiento and M.sec = @low1;

				select @monto = M.monto	
					from @movimientosCrear M
					where M.sec = @low1;
				
				if(@tipoMovimiento = 3 or @tipoMovimiento = 4 or @tipoMovimiento = 5 or @tipoMovimiento = 7 or
					@tipoMovimiento = 8 or @tipoMovimiento = 9 or @tipoMovimiento = 10 or @tipoMovimiento = 11)
					begin
						set @monto = @monto * -1;
					end;

				update Cuenta
					set saldo = saldo + @monto
					where idCliente = @tipoCuenta;

				set @low1 = @low1 + 1;
			end

		
		/*
		Calcular los intereses diarios (saldo * tasaInteres / 365)
		*/

		set @low1 = 1;
		select @hi1 = max(C.id) 
			from Cuenta C;

		while @low1 <= @hi1
			begin
				select @monto = C.saldo * T.tasaInteres / 365
					from Cuenta C, TipoCuenta T
					where C.id = @low1 and T.id = C.idTipoCuenta;

				update Cuenta 
					set interesesAcumulados = interesesAcumulados + @monto
					where id = @low1;
				set @low1 = @low1 + 1;
			end;

		
		/*
		Cerrar y (o) abrir estados de cuenta
		*/
		set @low1 = 1;
		select @hi1 = max(E.id)
			from EstadoCuenta E;

		while @low1 <= @hi1
			begin
				select @fechaEstadoCuenta = dateadd(month, -1 , @fechaOperacion);

				select @fechaEstadoCuenta = E.fechaInicial, @idCuenta = E.idCuenta, @monto = C.interesesAcumulados
					from EstadoCuenta E, Cuenta C
					where E.id = @low1 and C.id = E.idCuenta;
				
				update Cuenta
					set saldo = saldo + @monto
					where id = @idCuenta;

				update EstadoCuenta
					set fechaFinal = @fechaOperacion, enProceso = 0
					where id = @low1 and fechaInicial <= @fechaEstadoCuenta;

				set @low1 = @low1 + 1;
			end 
		
	end; -- Fin del while grande
	
use master
go