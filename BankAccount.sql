use master;

if(exists(select * from sysdatabases where name = 'BankAccount'))
begin
	drop database [BankAccount]
end

create database [BankAccount]
go

use [BankAccount]
go

create Table Cliente(
	id int identity primary key not null,
	nombre nvarchar(50),
	valorDocId int,
	contrasena nvarchar(20)
)

create Table Cuenta(
	id int identity primary key not null,
	idCliente int constraint FKCuenta_Cliente references Cliente(id) not null, --#LaLinea
	saldo money not null,
	fechaCreacion date not null,
	interesesAcumulados money not null
)



use [master];
go
