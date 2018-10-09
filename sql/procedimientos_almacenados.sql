use BankAccount
go

set dateformat dmy;  
go

create procedure dbo.casp_estadocuenta
@codigoCuenta nvarchar(50),
@salida as nvarchar(500) output 
	as
	begin
		declare @tmp int;
		select @tmp = max(EC.id)
		from EstadoCuenta EC
		where EC.idCuenta = @codigoCuenta and EC.enProceso = 0;

		select @salida = @salida + 'Cuenta: ' + cast(EC.idCuenta as nvarchar) + char(10)
								+ 'Fecha inicial: ' + cast(EC.fechaInicial as nvarchar) + char(10)
								+ 'Fecha final: ' + cast(EC.fechaFinal as nvarchar) + char(10)
								+ 'Saldo inicial: ' + cast(EC.saldoInicial as nvarchar) + char(10)
								+ 'Saldo final: ' + cast(EC.saldoFinal as nvarchar) + char(10)
								+ 'Saldo mínimo: ' + cast(EC.saldoMinimo as nvarchar) + char(10)
								+ 'Cantidad operaciones manuales: ' + cast(EC.cantMaxManual as nvarchar) + char(10)
								+ 'Cantidad operaciones ATM: ' + cast(EC.cantmMaxATM as nvarchar) + char(10)  
		from EstadoCuenta EC 
		where EC.id = @tmp
			
	end
go
  
create procedure dbo.casp_agregarcuenta
	@clienteId nvarchar(50), --valorDocId
	@tipoCuenta int,
	@salida as int output
	
	as
	begin

		set transaction isolation level read committed --Más lento pero más consistente
		begin transaction;
		begin try
			insert into Cuenta(fechaCreacion, idTipoCuenta, idCliente, codigoCuenta, interesesAcumulados, saldo)
				select getdate(), @tipoCuenta, C.id, 'No necesario', 0, 0
				from Cliente C
				where C.valorDocId = @clienteId;

			commit
			set @salida = 1;
			return 1;
		end try
		begin catch
			rollback;
			select error_message();
			set @salida = -1;
			return -1;
		end catch
	end
go

create procedure dbo.casp_movimiento
	@destinatario int, --id de cuenta
	@monto money,
	@tipoMov int, -- ATM = 2, Manual = 1 (+) -- Retiro ATM = 4, Retiro Manual = 3, Compras = 5 (-)
	--@postIp nvarchar(16)
	@salida as int output

	as
	begin;
		declare @tiempo time;
		declare @ip nvarchar(16);
		declare @fecha date = getdate();
		select @tiempo = cast(getdate() as time(0));

		if(@tipoMov = 3 or @tipoMov = 4)
		begin
			select @monto = @monto * - 1;
		end;

		if(@tipoMov = 1 or @tipoMov =3)
		begin
			set @ip = 'Manual';
		end;

		if(@tipoMov = 2 or @tipoMov =4)
		begin
			set @ip = 'ATM';
		end;
		set transaction isolation level read committed --Más lento pero más consistente
		begin transaction;
		begin try
					
			update Cuenta
				set saldo = saldo + @monto
				where id = @destinatario;

			--insert into Movimiento(fecha, idMovimiento, idTipoMovimiento, invisible, postIp, postTime, monto)
			--		select @fecha, @destinatario, @tipoMov, 0, @ip, @tiempo, @monto;
								
			commit
			set @salida = 1;
			return 1;
		end try
		begin catch
			rollback;
			select error_message();
			set @salida = -1;
			return -1;
		end catch
	end
go

create procedure dbo.casp_agregarcliente
@valorDocId nvarchar(50),
@nombre nvarchar(50),
@contrasenna nvarchar(50),
@salida as int output

	as
	begin
		set @salida = 1;
		set transaction isolation level read committed
		begin transaction
		begin try
			
				insert into Cliente(nombre, valorDocId, contrasenna, visible)
					values(@nombre, @valorDocId, @contrasenna, 1);
				commit
				return 1;
		end try
		begin catch
			rollback;
			select error_message();
			set @salida = -1;
			return -1;
		end catch
	end
go

create procedure dbo.casp_consultausuario
@valorDocId nvarchar(50),
@contrasenna nvarchar(50),
@salida as int output

	as
	begin
		begin try
			select @salida = 1
				from Cliente C
				where C.valorDocId = @valorDocId and C.contrasenna = @contrasenna;

			select @salida = 2
				from Administrador A
				where A.valorDocId = @valorDocId and A.contrasenna = @contrasenna;
			return 1;

		end try
		begin catch
			select error_message();
			set @salida=-1;
			return -1;
		end catch
	end
go

  
create procedure dbo.casp_estadocuenta
@codigoCuenta nvarchar(50),
@salida as nvarchar(500) output 
	as
	begin
		declare @tmp int;
		select @tmp = max(EC.id)
		from EstadoCuenta EC
		where EC.id = @codigoCuenta and EC.enProceso = 0;

		select @salida = @salida + 'Cuenta: ' + cast(EC.idCuenta as nvarchar) + char(10)
								+ 'Fecha inicial: ' + cast(EC.fechaInicial as nvarchar) + char(10)
								+ 'Fecha final: ' + cast(EC.fechaFinal as nvarchar) + char(10)
								+ 'Saldo inicial: ' + cast(EC.saldoInicial as nvarchar) + char(10)
								+ 'Saldo final: ' + cast(EC.saldoFinal as nvarchar) + char(10)
								+ 'Saldo mínimo: ' + cast(EC.saldoMinimo as nvarchar) + char(10)
								+ 'Cantidad operaciones manuales: ' + cast(EC.cantMaxManual as nvarchar) + char(10)
								+ 'Cantidad operaciones ATM: ' + cast(EC.cantmMaxATM as nvarchar) + char(10)  
		from EstadoCuenta EC 
		where EC.id = @tmp
			
	end
go


use master
go