use BankAccount
go


exec casp_agregarcliente '1234', 'Diego', '123';
exec casp_agregarcuenta '1234', 1, '000';
exec casp_movimiento '000', 1000, 1, 'Atm';

/*
https://stackoverflow.com/questions/7710449/how-to-get-time-from-datetime-format-in-sql
*/

use master
go