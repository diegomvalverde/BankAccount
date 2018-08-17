use master;

/*
The next segment of code is to manage de error of create an existing data base,
if the db exists, the code delete it and create a new db
*/

if(exists(select * from sysdatabases where name = 'BankAccount'))
begin
	drop database [BankAccount]
end

--// Tables creation

create database [BankAccount]
go

use [BankAccount]
go

create table Cliente
(
	id int identity primary key not null,
	nombre nvarchar(50) not null,
	valorDocId int not null,
	contrasena nvarchar(20) not null
)

create table TipoCuenta
(
	id int identity primary key not null,
	nombre nvarchar(50) not null,
	tasaInteres float not null,
	saldoMin money not null,
	cantMaxMAnual int not null,
	cantMaxATM int not null,
	multaSaldoMin money not null,
	multaCantMaxManual money not null,
	multaCantmaxATM money not null,
	mulaSaldoNegativo money not null,
	cargoServicio money not null
)

create table Cuenta
(
	id int identity primary key not null,
	idCliente int constraint FKCuenta_Cliente references Cliente(id) not null, --#LaLinea
	saldo money not null,
	fechaCreacion date not null,
	interesesAcumulados money not null
)

create table TipoMovimiento
(
	id int primary key not null,
	nombre nvarchar(20) 
)

create table Movimiento
(
	id int identity primary key not null,
	idMovimiento int constraint FKMovimiento_Cuenta references Cuenta(id) not null,
	idTipoMovimiento int constraint FKMovimiento_TipoMovimiento references TipoMovimiento(id) not null,
	fecha date not null,
	postIp nvarchar(216) not null,
	postTime time not null,
	invisible bit not null
)



--// This code is to don't have to restart MSQLMS if an error occurs.
use [master];
go