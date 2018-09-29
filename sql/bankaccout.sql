use master;

/*
El siguiente segmento de código es para manejar el error de crearuna base de datos
existente, si la base de datos existe se borra y se crea una nueva.
*/

if(exists(select * from sysdatabases where name = 'BankAccount'))
begin

	drop database [BankAccount]
	
end


--// Creación de la base de datos si no existe.

create database [BankAccount]
go

use [BankAccount]
go


--// Creación de tablas.

create table Administrador
(
	id int identity primary key not null,
	nombre nvarchar(50) not null,
	valorDocId nvarchar(50) not null,
	contrasenna nvarchar(50) not null
)

create table Cliente
(
	id int identity primary key not null,
	nombre nvarchar(50) not null,
	valorDocId nvarchar(10) not null,
	contrasenna nvarchar(20) not null,
	visible bit not null
)

create table TipoCuenta
(
	id int primary key not null,
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
	interesesAcumulados money not null,
	codigoCuenta nvarchar(50) not null
)

create table TipoMovimiento
(
	id int primary key not null,
	nombre nvarchar(50) not null,
	descripcion nvarchar(200) not null
)

create table Movimiento
(
	id int identity(1,1) primary key not null,
	idMovimiento int constraint FKMovimiento_Cuenta references Cuenta(id) not null,
	idTipoMovimiento int constraint FKMovimiento_TipoMovimiento references TipoMovimiento(id) not null,
	fecha date not null,
	postIp nvarchar(16) not null,
	postTime time not null,
	invisible bit not null,
	monto money not null
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
	enProceso bit not null
)


create table MovimientoInteres
(
	id int identity(1,1) primary key not null,
	tipoMovInteres int constraint FKEstadoMovimientoInteres_TipoMovIntereses references Cuenta(id) not null,
	fecha date not null,
	saldo money not null,
	interesDiario float not null
)

create table TipoMovInteres
(
	id int primary key not null,
	nombre nvarchar(50) not null,
	descripcion nvarchar(50) not null
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
	id int primary key not null,
	nombre nvarchar(50) not null,
	descripcion nvarchar(50) not null
)


--// Inserciones importantes
insert into Administrador(contrasenna, nombre, valorDocId)
values ('diego', 'diego', '604400433');
go


--// Este código es para no tener que reiniciar la DB si ocurre un error con MSQLMS
use [master];
go

