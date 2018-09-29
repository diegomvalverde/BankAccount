use BankAccount
go

set dateformat dmy;  
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
	@destinatario nvarchar(50), --Numero de cuenta (codigoCuenta)
	@monto money,
	@tipoMov int, -- ATM = 2, Manual = 1 (+) -- Retiro ATM = 4, Retiro Manual = 3, Compras = 5 (-)
	--@postIp nvarchar(16)
	@salida as int output

	as
	begin;
		declare @idCuenta nvarchar(50);
		declare @tiempo time;
		select @tiempo = cast(getdate() as time(0));

		if(@tipoMov >= 4 and @tipoMov <= 6)
		begin
			select @monto = @monto * - 1;
		end;

		set transaction isolation level read committed --Más lento pero más consistente
		begin transaction;
		begin try

			insert into Movimiento(fecha, idMovimiento, idTipoMovimiento, invisible, monto, postIp, postTime)
				select getdate(), C.id, @tipoMov, 0, @monto, 'Desconocido', @tiempo
				from Cuenta C
				where C.codigoCuenta = @destinatario;

			update Cuenta
				set saldo = saldo + @monto
				where codigoCuenta = @destinatario;
								
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

--create procedure dbo.casp_estadocuenta
--@codigoCuenta nvarchar(50)

--	as
--	begin
--		declare @estados table
--		(
--			fechaInicial date not null,
--			fechaFinal date not null,
--			saldoInicial money not null,
--			saldoFinal money not null,
--			saldoMinimo money not null,
--			cantMaxManual int not null,
--			cantmMaxATM int not null
--		)

--		insert @estados(fechaInicial, fechaFinal, cantmMaxATM, cantMaxManual, saldoFinal, saldoInicial, saldoMinimo)
--			select null
--			from EstadoCuenta E
--			where E.
--		--set transaction isolation level read committed
--		--begin transaction
--		--begin try
--		--		insert 
--		--		return 1;
--		--end try
--		--begin catch
--		--	--rollback;
--		--	select error_message();
--		--	return -1;
--		--end catch
--	end
--go


use master
go