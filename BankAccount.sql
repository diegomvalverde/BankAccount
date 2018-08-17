use master;

/*
The next segment of code is to manage de error of create an existing data base,
if the db exists, the code delete it and create a new db
*/

if(exists(select * from sysdatabases where name = 'BankAccount'))
begin
	drop database [BankAccount]
end


--// DB creation if it doesn't exists.

create database [BankAccount]
go

use [BankAccount]
go


--// Tables creation

create table Admin
(
	id int identity primary key not null,
	nombre nvarchar(50) not null,
	valorDocId int not null,
	password nvarchar(50) not null
)

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
	idTipoCuenta int constraint FKCuenta_TipoCuenta references TipoCuenta(id) not null,
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

create table EstadoCuenta
(
	id int identity primary key not null,
	idCuenta int constraint FKEstadoCuenta_Cuenta references Cuenta(id) not null,
	nombre nvarchar(50) not null,
	fechaInicial date not null,
	fechaFinal date not null,
	saldoInicial money not null,
	saldoFinal money not null,
	saldoMinimo money not null,
	cantMaxManual int not null,
	cantmMaxATM int not null,
)


create table MovimientoInteres
(
	id int identity primary key not null,
	fecha date not null,
	saldo money not null,
	interesDiario float not null
)

create table TipoMovInteres
(
	id int identity primary key not null,
	nombre nvarchar(50) not null,
)

create table Evento
(
	id int identity primary key not null,
	postIP nvarchar(16) not null,
	postTime date not null,
	xmlAntes xml not null,
	xmlDepues xml not null,
	entidadID bit not null, --//?
)

create table TipoEvento
(
	id int identity primary key not null,
	nombre nvarchar(50) not null,
)


--// Inserciones importantes

insert into Admin(nombre, password, valorDocId)
	values('Admin', 'Admin', 0);
go


--// This code is to don't have to restart MSQLMS if an error occurs.
use [master];
go
