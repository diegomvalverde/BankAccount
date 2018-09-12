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
	select * from openrowset(bulk 'C:\Bases\Operaciones.xml', single_blob) as x
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
Agregar los tipos de cuanta a las tablas de la base de datos
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

set @low1 = 1;
select @hi1 = max(T.sec) from @TipoMovimientoCrear T;

while @low1 <= @hi1
	begin
		insert into TipoMovimiento(id, nombre, descripcion)
			select T.id, T.nombre, T.descripcion
			from @TipoMovimientoCrear T
			where T.id = @low1;

		set @low1 = @low1 + 1;
	end;

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
Se agregan los clientes (uno por uno) guardados en la tabla temporal de clientes en la tabla Clientes de la BD.
*/

set @low1 = 1;
select @hi1 = max(C.sec)
	from @clientesCrear C;

while @low1 <= @hi1
	begin

		insert into Cliente(nombre, valorDocId, contrasenna, visible)
			select C.nombre, C.docId, C.contrasenna, 1
			from @ClientesCrear C
			where @low1 = C.sec;

		set @low1 = @low1 + 1;
	end;


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
Se agregan todas las cuentas de la tabla temporal de cuentas (una por una) a la tabla Cuentas de la BD y se abre un estado
de cuenta para estas nuevas cuentas.
*/

select @low1 = 1;
select @hi1 = max(C.id) 
	from @CuentasCrear C;

while @low1 <= @hi1
	begin
		insert into Cuenta(fechaCreacion, idCliente, idTipoCuenta, interesesAcumulados, saldo, codigoCuenta)
			select CC.fecha, C.id, CC.tipoCuenta, 0, 0, CC.codigoCuenta
			from @CuentasCrear CC, Cliente C
			where C.id = @low1 and CC.idCliente = C.valorDocId;

		insert into EstadoCuenta(idCuenta, nombre, saldoInicial, saldoFinal, fechaInicial, fechaFinal, cantmMaxATM, cantMaxManual, enProceso, saldoMinimo)
			select C.idCliente, 'Estado de cuenta', C.saldo, C.saldo, C.fechaCreacion, C.fechaCreacion, 0, 0, 1, C.saldo
			from Cuenta C
			where C.id = @low1;

		set @low1 = @low1 + 1;
	end;


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

set @fechaIncio = 1;
select @fechaFinal = max(F.id)
	from @Fechas F;


/*
While grande para recorrer por fechas.
*/

while @fechaIncio <= @fechaFinal
	begin

		delete @ClientesCrear;
		delete @CuentasCrear;
		--delete @movimientosCrear;

		select @fechaOperacion = F.fecha
			from @Fechas F
			where F.id = @fechaIncio;

		/*
		Se insertan los movimientos (uno por uno) de la tabla temporal de movimientos en la tabla Movimientos de la BD y
		se actualiza la cuenta y el estado de cuenta en curso.
		*/

		select @hi1 = max(M.sec), @low1 = min(M.sec)  
			from @movimientosCrear M
			where @fechaOperacion = M.fecha;

		while @low1 <= @hi1
			begin
				-- El moviento
				select @tiempo = convert(varchar(10), GETDATE(), 108) -- Optener el tiempo u hora en que se hace el movimiento

				-- Inserta un movimiento en la BD.
				insert into Movimiento(fecha, idMovimiento, idTipoMovimiento, invisible, postIp, postTime, monto)
					select M.fecha, C.id, M.tipoMovimiento, 0, 'Unknown', @tiempo, M.monto
					from Cuenta C, @movimientosCrear M
					where C.codigoCuenta = M.codigoCuenta_Movimiento and @low1 = M.sec;

				select @monto = M.monto
					from @movimientosCrear M
					where M.sec = @low1;

				
				select @idCliente = C.idCliente, @tipoMovimiento = M.tipoMovimiento
					from Cuenta C, @movimientosCrear M
					where C.codigoCuenta = M.codigoCuenta_Movimiento and M.sec = @low1;
				
				-- Suma o resta al saldo dependiendo del tipo de movimiento
				if(@tipoMovimiento = 3 or @tipoMovimiento = 4 or @tipoMovimiento = 5 or @tipoMovimiento = 7 or
					@tipoMovimiento = 8 or @tipoMovimiento = 9 or @tipoMovimiento = 10 or @tipoMovimiento = 11)
					begin
						update Cuenta
							set saldo = saldo - @monto
							where idCliente = @idCliente;
					end;
				else
					begin
						update Cuenta
							set saldo = saldo + @monto
							where idCliente = @idCliente;
					end;

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

				select @fechaOperacion = dateadd(month, -1 , @fechaOperacion);

				select @fechaEstadoCuenta = E.fechaInicial, @idCuenta = E.idCuenta
					from EstadoCuenta E
					where E.id = @low1;

				if (@fechaOperacion >= @fechaEstadoCuenta)
				begin
					update Cuenta
						set saldo = saldo + interesesAcumulados, interesesAcumulados = 0
						where id = @idCuenta;

					select @monto = C.saldo
						from Cuenta C
						where id = @idCuenta;
					
					update EstadoCuenta
						set fechaFinal = @fechaOperacion, enProceso = 0, saldoFinal = @monto
						where id = @low1;
				end;

				set @low1 = @low1 + 1;
			end 

		set @fechaIncio = @fechaIncio + 1;
	
	end; -- Fin del while grande
	go

	/*
	https://stackoverflow.com/questions/668087/sql-server-openxml-how-to-get-attribute-value
	https://www.blogger.com/blogger.g?blogID=4475082695685755918#allposts/postNum=0
	*/

set nocount off
use master
go