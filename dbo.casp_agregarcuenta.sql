	use BankAccount
go

create procedure dbo.casp_agregarcuenta
	@cliente nvarchar(50), --valorDocId
	@tipoCuenta int
	
	as
	begin;
		declare @fechaActual date;
		set @fechaActual = GETDATE();
		declare @id int;
		select @id = C.id from Cliente C where @cliente = C.valorDocId;

		begin try
			set transaction isolation level read uncommitted
			begin transaction
				insert Cuenta(fechaCreacion, idTipoCuenta, idCliente)
					values(@fechaActual, @tipoCuenta, @id);
				commit
				return 1;

		end try
		begin catch

		end catch
	end
go

create procedure dbo.casp_depositar
	@destinatario nvarchar(50), --Numero de cuenta
	@monto money,
	@tipoCajero nvarchar(50) --ATM, Manual, etc...

	as
	begin
		begin try
			set transaction isolation level read uncommitted
			begin transaction
	
				commit
				return 1;

		end try
		begin catch

		end catch
	end
go

create procedure dbo.casp_estadocuenta
	as
	begin
		begin try
			set transaction isolation level read uncommitted
			begin transaction

				commit
				return 1;

		end try
		begin catch

		end catch
	end
go

use master
go