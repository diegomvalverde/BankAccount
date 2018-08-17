/*
Script para la simulación de entrada de grands cantidades de datos, los datos
se leen de un xml.
*/

use BankAccount
go

declare @XML xml
set @XML = 
(
	select * from openrowset(bulk 'xml\path', single_blob) as data
)

declare @handle int  
declare @PrepareXmlStatus int  
exec @PrepareXmlStatus= sp_xml_preparedocument @handle output, @XML

declare @fechaIncio int = 0;
declare @fechaFinal int = 10;

declare @ClientesCrear table
(
	sec int identity(1,1),
	docId nvarchar(10),
	nombre nvarchar(50)
)



while @fechaIncio <= @fechaFinal
	begin
		delete @ClientesCrear;

		--// Insercion de los clientes en la tabla temporal
		insert @ClientesCrear (docId, nombre)
		select docId, nombre
		from openxml(@handle, 'XML/termData/term') with (docId int, nombre nvarchar(50));

		set @fechaIncio = @fechaIncio + 1;
	end;

use master
go