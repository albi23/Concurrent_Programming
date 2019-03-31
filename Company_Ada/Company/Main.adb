with Ada.Text_IO;   use Ada.Text_IO;
with configuration; use configuration;
with functions;     use functions;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with GNAT.OS_Lib;


procedure Main is 

     ChosedMode : String(1 .. 1);
     Last : Natural;
     boss : BossTask;
     Choice : Integer;
     T : array (1 .. numbeOfEmployees) of Workertype;
    
begin
    Put_Line("Choose: deceptive mode/quiet mode  D/Q: ");
    Get_Line(ChosedMode,Last);
    
    if( ChosedMode(1 .. Last) = "D" ) then 
        deceptive := true;
    elsif ( ChosedMode(1 ..Last) = "Q") then
        Put_Line ("Q") ;
    else 
        Put_Line ("Bad option this is the end of visible world for you.");
        GNAT.OS_Lib.OS_Exit (0);    
    end if; 
    
   -- Start of working boss 
    boss.Start;
    
   -- Start of working employees 
   for I in T'Range loop
    T(I).Go(I);
   end loop;
   
   -- Run quiet mode 
   if deceptive = false then
     loop
        Put_Line("Choose: ");
        Put_Line("       1 to check warehouse ");
        Put_Line("       2 to check tasks ");
        Put_Line("       3 to exit ");
        Get(Choice);
        case Choice is 
                when 1 => functions.printWarehouseElements;
                when 2 => functions.printTaskToDo;
                when 3 => GNAT.OS_Lib.OS_Exit (0);
                when others =>  Put_Line("Unknown"); 
            end case;
     end loop;
   end if;    

end Main;