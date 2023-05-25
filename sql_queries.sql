-- ZADANIE 2

/*Jakie są miasta, w których mieszka więcej niż 3 pracowników?*/

select*
from (
					select distinct 
					e.city,
					count(e.city) over (partition by e.city) liczba_pracownikow
					from employees e) liczba_prac
where liczba_pracownikow>3;


					
/*Zakładając, że produkty, które kosztują (UnitPrice) mniej niż 10$
możemy uznać za tanie, te między 10$ a 50$ za średnie, a te powyżej
50$ za drogie, ile produktów należy do poszczególnych przedziałów?*/


select distinct  przedziały_cenowe,
count(przedziały_cenowe) over (partition by przedziały_cenowe order by przedziały_cenowe) liczba_produktów_należących_do_przedziałow_cenowych
from  (
					select *,
					case
						when p.unit_price<10 then 'tanie'
						when p.unit_price between 10 and 50 then 'średnie'
						else 'drogie'
					end przedziały_cenowe
					from products p) przedziały_cenowe;

				
/* Czy najdroższy produkt z kategorii z największą średnią ceną to
najdroższy produkt ogólnie?*/


select distinct
p.category_id,
round(avg(p.unit_price) over (partition by p.category_id)::numeric,2) as średnia_cena,
round(max(p.unit_price) over (partition  by p.category_id)::numeric,2) as najdrozszy
from products p 
order by  p.category_id  asc;
			
--Odpowiedź: najdroższy produkt jest w kategorii 1 a nie 6 

/*Ile kosztuje najtańszy, najdroższy i ile średnio kosztuje produkt od
każdego z dostawców? UWAGA – te dane powinny być przedstawione
z nazwami dostawców, nie ich identyfikatorami*/



select distinct
s.company_name ,
round(min(p.unit_price) over (partition by s.company_name order by company_name)::numeric,2 ) as wartość_min_produktu,
round(max(p.unit_price) over (partition by s.company_name order by company_name)::numeric,2) as wartość_max_produktu,
round(avg(p.unit_price) over (partition by s.company_name order by company_name)::numeric,2) as wartość_średnia_produktu
from products p
join suppliers s 
on p.supplier_id =s.supplier_id; 



/*Jak się nazywają i jakie mają numery kontaktowe wszyscy dostawcy i
klienci (ContactName) z Londynu? Jeśli nie ma numeru telefonu,
wyświetl faks.*/


select s.contact_name, s.city , coalesce(s.phone, s.fax)  as phone_lub_fax, 'suppliers' as zródło_danych
from suppliers s
where s.city='London'
union all
select c.contact_name, c.city, coalesce(c.phone, c.fax)  as phone_lub_fax, 'customers' as zródło_danych
from customers c  
where c.city='London'



/*Które miejsce cenowo (od najtańszego) zajmują w swojej kategorii
(CategoryID) wszystkie produkty?*/


select product_name,
unit_price cena,
category_id,
rank() over (partition by category_id order by unit_price) ranking
from products p 
order by category_id;

--ZADANIE 4

/*Jaka była i w jakim kraju miała miejsce najwyższa dzienna amplituda
temperatury?*/

		
		select *
		from (
					select *,
					max(amplituda_dobo) over (order by amplituda_dobo desc) max_temp
					from 
					(
											select*,
														(
														select max(abs(maxtemp-mintemp))
														from summary_of_weather sow  
														where  sow.sta=wsl.wban
														) as amplituda_dobo
											from weather_station_locations wsl								
					) max_temperatura
			) razem
		where amplituda_dobo=max_temp;
									



/*Z czym silniej skorelowana jest średnia dzienna temperatura dla stacji
– szerokością (lattitude) czy długością (longtitude) geograficzną?*/

select 
corr(sow.meantemp,wsl.latitude) korelacja_z_szerokością,
corr(sow.meantemp,wsl.longitude) korelacja_z_szerokością
from summary_of_weather sow
join weather_station_locations wsl 
on sow.sta =wsl.wban
					 



---odp. z szerokością
					 
 /*Pokaż obserwacje, w których suma opadów atmosferycznych
(precipitation) przekroczyła sumę opadów z ostatnich 5 obserwacji na
danej stacji.*/

drop view v_opady


update summary_of_weather 
	set precip = '0'
	where precip = 'T'
								
create view v_opady as
select 
sta, 
data_::date,
precip::numeric opady_z_dnia,
lag(precip) over (partition by sta order by data_::date) dzień_wstecz,
lag(precip,2) over (partition by sta order by data_::date) dwa_dni_wstecz,
lag(precip,3) over (partition by sta order by data_::date) trzy_dni_wstecz,
lag(precip,4) over (partition by sta order by data_::date) cztery_dni_wstecz,
lag(precip,5) over (partition by sta order by data_::date) pięć_dni_wstecz
from summary_of_weather sow


select*from v_opady;



select 
sta, data_, opady_z_dnia, suma_opadów_z_ostatnich_5_dni
from(
					select
					*,
					vo."dzień_wstecz"::numeric  + vo."dwa_dni_wstecz"::numeric  + vo."trzy_dni_wstecz"::numeric + vo."cztery_dni_wstecz"::numeric  + vo."pięć_dni_wstecz"::numeric  as suma_opadów_z_ostatnich_5_dni
					from v_opady vo				
					
) tabela_opadow
where opady_z_dnia > suma_opadów_z_ostatnich_5_dni;

		
	