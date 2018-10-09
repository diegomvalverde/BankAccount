/*
Script para la simulación de entrada de grands cantidades de datos, los datos
se leen de un xml.
*/
use BankAccount
go

set dateformat dmy;  
go  

set nocount on -- No mostrar las filas agregadas

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

/*
Variables importantes
*/

declare @fechaOperacionString varchar(20);
declare @fechaOperacion date;	-- Para comparar con el id fecha en xml
declare @fechaEstadoCuenta date;		-- Para ver si los estados de cuentas necesitan cerrarse
declare @low1 int;						-- Variable para loops
declare @hi1 int;						-- Variable para loops
declare @tiempo time;					-- Hora de la operacion leida del xml


declare @valorDocId nvarchar(50);
declare @nombre nvarchar(50);
declare @contrasenna nvarchar(50);
declare @idCuenta nvarchar(50);
declare @tipoCuenta int;
declare @monto money;
declare @tipoMovimiento int;
declare @idCliente int;

--Variables del xml
declare @handle int;  
declare @PrepareXmlStatus int;  
declare @ops xml;


-- Iterar el xml por fechas
declare @fechaIncio int;
declare @fechaFinal int;


/*
Creacion de las tablas temporales
*/

declare @ClientesCrear table 
(
	sec int identity(1,1),
	docId nvarchar(10),
	nombre nvarchar(50),
	contrasenna nvarchar(50),
	fecha date
);


declare @CuentasCrear table
(
	id int identity(1,1),
	idCliente nvarchar(50),
	tipoCuenta int,
	codigoCuenta nvarchar(100),
	fecha date
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
	sec int identity(1,1),
	fecha date
)

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
	select y.fecha.value('(@fecha)', 'date')
		from @xmlOps.nodes('/dataset/fechaOperacion') as y(fecha);

/*
Agregar los tipos de movimientos interes temporales a la tabla de la base de datos
*/ 

insert into TipoMovInteres(id, nombre, descripcion)
	select T.id, T.nombre, T.descripcion
	from @TipoMovInteresCrear T;

/*
Agregar los tipos de cuanta a las tablas de la base de datos
*/

insert into TipoCuenta(id, cantMaxATM, cantMaxMAnual, cargoServicio, mulaSaldoNegativo, multaCantmaxATM, 
	multaCantMaxManual, multaSaldoMin, nombre, saldoMin, tasaInteres)
	select T.id, T.cantMaxATM, T.cantMaxMAnual, T.cargoServicio, T.mulaSaldoNegativo, T.multaCantmaxATM,
			T.multaCantMaxManual, T.multaSaldoMin, T.nombre, T.saldoMin, T.tasaInteres 
	from @TiposCuentaCrear T;
/*
Guardar los Administradores de la tabla temporal en la tabla de la base de datos.
*/ 

insert into Administrador(nombre, valorDocId, contrasenna)
	select A.nombre, A.idAdmin, A.contrasenna
	from @AdminsCrear A;

/*
Cargar los tipos de evento de la tabla temporal en la tabla de la base de datos.
*/ 

insert into TipoEvento(id, nombre, descripcion)
	select T.id, T.nombre, T.descripcion
	from @TipoEventoCrear T
	where T.id = @low1;

/*
Cargar los tipos de movimientos de la tabla temporal en la tabla de la base de datos.
*/ 

insert into TipoMovimiento(id, nombre, descripcion)
	select T.id, T.nombre, T.descripcion
	from @TipoMovimientoCrear T;

/*
Se leen los datos de los clientes del xml, sólo los correspondientes a una fecha y se guardan en la tabla temporal de clientes
Insercion de los clientes en la tabla temporal de clientes para posteriormente agregarlas a la tabla Clientes de la BD.
*/
	
insert @ClientesCrear(nombre, docId, contrasenna, fecha)
	select y.fecha.value('@nombre', 'nvarchar(50)'),
		y.fecha.value('@valorDocId', 'nvarchar(50)'),					
		y.fecha.value('@contrasenna', 'nvarchar(50)'),
		y.fecha.value('(../@fecha)', 'date')
		from @xmlOps.nodes('/dataset/fechaOperacion/Cliente') as y(fecha);
/*
Se agregan los clientes (todos a la vez) guardados en la tabla temporal de clientes en la tabla Clientes de la BD.
*/

insert into Cliente(nombre, valorDocId, contrasenna, visible)
	select C.nombre, C.docId, C.contrasenna, 1
	from @ClientesCrear C;

/*
Se leen las cuentas por fecha y se agregan a la tabla temporal de cuentas para posteriormente ser agregadas a la 
tabla clientes de la BD.
*/

insert @CuentasCrear(idCliente, tipoCuenta, codigoCuenta, fecha)
	select y.id.value('@docIdCliente', 'nvarchar(50)'),
			y.id.value('@tipoCuenta', 'int'),					
			y.id.value('@codigoCuenta', 'nvarchar(50)'),
			y.id.value('(../@fecha)', 'date')
			from @xmlOps.nodes('/dataset/fechaOperacion/Cuenta') as Y(ID)

/*
Se agregan todas las cuentas de la tabla temporal de cuentas (todas a la vez) a la tabla Cuentas de la BD y se abre un estado
de cuenta para estas nuevas cuentas.
*/

insert into Cuenta(fechaCreacion, idCliente, idTipoCuenta, interesesAcumulados, saldo, codigoCuenta)
	select CC.fecha, C.id, CC.tipoCuenta, 0, 0, CC.codigoCuenta
	from @CuentasCrear CC, Cliente C
	where CC.idCliente = C.valorDocId;

insert into EstadoCuenta(idCuenta, nombre, saldoInicial, saldoFinal, fechaInicial, fechaFinal, cantmMaxATM, cantMaxManual, enProceso, saldoMinimo)
	select C.idCliente, 'Estado de cuenta', C.saldo, C.saldo, C.fechaCreacion, C.fechaCreacion, 0, 0, 1, C.saldo
	from Cuenta C;

/*
Se leen los movimientos del xml por fechas y se guardan en la tabla temporal de los movimientos para posteriormente ser 
agregados a la BD.
*/

insert @movimientosCrear(monto, tipoMovimiento, descripcion, codigoCuenta_Movimiento, fecha)
	select y.id.value('@monto', 'money'),
			y.id.value('@tipoMovimiento', 'int'),
			y.id.value('@descripcion', 'nvarchar(50)'),				
			y.id.value('@codigoCuenta_Movimiento', 'nvarchar(50)'),
			y.id.value('(../@fecha)', 'date')
			from @xmlOps.nodes('/dataset/fechaOperacion/Movimiento') as Y(ID)

-- Lectura de la cantidad de fechas del xml
set @fechaIncio = 1;
select @fechaFinal = max(F.id)
	from @Fechas F;

/*
Se insertan los movimientos (todos a la vez con un while para los intereses diarios) de la tabla temporal de movimientos en la tabla 
Movimientos de la BD y se actualiza la cuenta y el estado de cuenta en curso.
*/

while @fechaIncio <= @fechaFinal
	begin

		select @tiempo = convert(varchar(10), GETDATE(), 108) -- Optener el tiempo u hora en que se hace el movimiento
		select @fechaOperacion = F.fecha 
			from @Fechas F
			where F.id = @fechaIncio;

		-- Inserta un movimiento
		insert into Movimiento(fecha, idMovimiento, idTipoMovimiento, invisible, postIp, postTime, monto)
			select M.fecha, C.id, M.tipoMovimiento, 0, 'XML', @tiempo, M.monto
			from Cuenta C, @movimientosCrear M
			where C.codigoCuenta = M.codigoCuenta_Movimiento and M.fecha = @fechaOperacion;

		-- Se inserta un evento al modificar en el cliente
		insert into Evento(tipoEvento, postDate, postIp)
			select TE.id, @fechaOperacion, 'Banco'
			from TipoEvento TE
			where TE.id = 5;

		-- Suma o resta al saldo dependiendo del tipo de movimiento (en la cuenta)
		update Cuenta
			set saldo = saldo - M.monto
			from @movimientosCrear M
			where M.fecha = @fechaOperacion and M.codigoCuenta_Movimiento = codigoCuenta and (M.tipoMovimiento = 3 or M.tipoMovimiento = 4 or M.tipoMovimiento = 5 or
																M.tipoMovimiento = 7 or M.tipoMovimiento = 8 or M.tipoMovimiento = 9
																or M.tipoMovimiento = 10 or M.tipoMovimiento = 11 );

		update Cuenta
			set saldo = saldo + M.monto
			from @movimientosCrear M
			where M.fecha = @fechaOperacion and M.codigoCuenta_Movimiento = codigoCuenta and (M.tipoMovimiento = 1 or M.tipoMovimiento = 2 or M.tipoMovimiento = 6);

		-- Cambia el saldo minimo de la cuenta por inserciones
		update EstadoCuenta 
			set saldoMinimo = C.saldo
			from Cuenta C
			where C.saldo < saldoMinimo and idCuenta = C.id and enProceso = 1;

		/*
		Calcular los intereses diarios (saldo * tasaInteres / 365 / 100)
		*/

		-- Se inserta un evento al modificar en el cliente
		insert into Evento(tipoEvento, postDate, postIp)
			select TE.id, @fechaOperacion, 'Banco'
			from TipoEvento TE, Cuenta C
			where TE.id = 5;

		update Cuenta 
			set interesesAcumulados = interesesAcumulados + (saldo * T.tasaInteres /365 / 100)
			from TipoCuenta T
			where T.id = idTipoCuenta and saldo > 0;

		/*
		Cerrar y (o) abrir estados de cuenta
		*/

		-- Se inserta un movimiento para agregar los intereses acumulados
		insert into MovimientoInteres(fecha, interesDiario, saldo, tipoMovInteres)
			select @fechaOperacion, T.tasaInteres, C.interesesAcumulados, 2
			from Cuenta C, TipoCuenta T
			where C.idTipoCuenta = T.id and C.fechaCreacion = @fechaEstadoCuenta;

		 --Crea un nuevo estado de cuenta para los estados que se cierran
		insert into EstadoCuenta(idCuenta, nombre, saldoInicial, saldoFinal, fechaInicial, fechaFinal, cantmMaxATM, cantMaxManual, enProceso, saldoMinimo)
			select C.idCliente, 'Estado de cuenta', C.saldo, 0, @fechaOperacion, @fechaOperacion, 0, 0, 1, C.saldo
			from Cuenta C, EstadoCuenta E
			where E.idCuenta = C.id and dateadd(month, 1 , E.fechaInicial) = @fechaOperacion;

		-- Se actualiza el estado de cuenta anterior
		update EstadoCuenta
			set fechaFinal = @fechaOperacion, enProceso = 0, saldoFinal = C.saldo
			from Cuenta C
			where C.id = idCuenta and dateadd(month, 1 , fechaInicial) = @fechaOperacion and enProceso = 1;

		-- Se inserta un evento al modificar en el cliente
		insert into Evento(tipoEvento, postDate, postIp)
			select TE.id, @fechaOperacion, 'Banco'
			from TipoEvento TE
			where TE.id = 5;

		update Cuenta
			set saldo = saldo + interesesAcumulados, interesesAcumulados = 0
			from EstadoCuenta E
			where E.idCuenta = idCuenta and dateadd(month, 1 , E.fechaInicial) = @fechaOperacion and E.enProceso = 0;

		set @fechaIncio = @fechaIncio + 1;
	end;

--	/*
--	https://stackoverflow.com/questions/668087/sql-server-openxml-how-to-get-attribute-value
--	https://www.blogger.com/blogger.g?blogID=4475082695685755918#allposts/postNum=0
--	*/
go
set nocount off
use master
go