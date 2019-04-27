with  Ada.Text_IO;  use  Ada.Text_IO;
with Ada.Numerics.discrete_Random;
with configuration; use configuration;

package body functions is

  listOfTask : array(0 .. maxSizeOfTasks) of Tasks;
  listOfResultsInWarehouse : array(0 .. maxSizeOfWarehouse) of Integer;
  actualSizeOfTasks : Integer := 0;
  actualSizeOfWarehouse : Integer := 0;
  taskBuffer : TasksListBuffer;
  listOfWarehouseBuffer : WarehouseBuffer;
  clientOne : Client;

-- *********************************
-- Function for return result tasks 
-- *********************************
 function CalculateTask(x : in Tasks) return Integer is
 begin
   case x.operation is
       when '+' => return x.firstArg + x.secondArg;
       when '-' => return x.firstArg - x.secondArg;
       when others => return x.firstArg * x.secondArg;
   end case;
 end CalculateTask;

-- **************************************
-- Task control add/remove item on/from warehouselist
-- **************************************
  task body WarehouseBuffer is
  begin
    loop
    select 
        when actualSizeOfWarehouse < maxSizeOfWarehouse =>
            accept InsertToWarehouse ( newResult : in Integer) do
            listOfResultsInWarehouse(actualSizeOfWarehouse) := newResult;
            actualSizeOfWarehouse := actualSizeOfWarehouse + 1;
            end InsertToWarehouse;
    or
        when actualSizeOfWarehouse > 0 =>
            accept RemoveFromWarehouse  do
                   actualSizeOfWarehouse := actualSizeOfWarehouse - 1;
            end RemoveFromWarehouse;
    end select;                
    end loop;  
  end WarehouseBuffer;
  

-- ****************************************************************************
-- Task control add/remove item on task list and put results to warehouse list
-- ****************************************************************************
  task body TasksListBuffer is
  begin
    loop
      select
        when actualSizeOfTasks < maxSizeOfTasks =>
            accept  Insert ( newTask : in Tasks) do
                listOfTask(actualSizeOfTasks) := newTask;
                actualSizeOfTasks := actualSizeOfTasks +1;
            end Insert;    
      or
        when  actualSizeOfTasks > 0 =>
            accept  Remove (  idWorker : in Integer) do
                actualSizeOfTasks := actualSizeOfTasks -1;
            end Remove;   
      end select;
    end loop;   
  end TasksListBuffer;
  

-- **********************
-- Client task symulation
-- **********************
  task body Client is begin
    delay fastOfEmployees*2.0;
    loop
        listOfWarehouseBuffer.RemoveFromWarehouse;
        if(deceptive = true) then 
            put_line("[Client] bought : "&Integer'image(listOfResultsInWarehouse(actualSizeOfWarehouse)));
        end if;
        delay 1.0*fastOfClient;
    end loop;
  end Client;
  
-- ***************************
-- Boss Simulation in company
-- ***************************
 task body BossTask is
    TaskToDo : Tasks;
    operations : array(0 .. 2) of Character;
 begin
    accept Start; 
     loop 
        operations := ('+','-','*');
        TaskToDo := (randNumber(rangeOfRandomNumber),randNumber(rangeOfRandomNumber),(operations(randNumber(2))));
        if(deceptive = true) then 
          put_line("Task : {"&Integer'image(TaskToDo.firstArg) &","&Integer'image(TaskToDo.secondArg) & "," & Character'image(TaskToDo.operation) &"}");
        end if;
        taskBuffer.Insert(TaskToDo);
        delay 1.0*delayBossTask;
      end loop;  
 end BossTask;  
 
 -- **************************************
 -- Simulation of employees in the company
 -- **************************************
  task body  Workertype is 
    nr : Integer;
  begin
    accept go( nrWorkers : Integer) do 
           nr := nrWorkers;
    end go;     
    loop        
      delay 1.0*fastOfEmployees;
      taskBuffer.Remove(nr);
      if(deceptive = true) then 
         put_line("[Worker" &Integer'image(nr) & "] Operation to do : " &Integer'image(listOfTask(actualSizeOfTasks).firstArg) & Character'image(listOfTask(actualSizeOfTasks).operation) &Integer'image(listOfTask(actualSizeOfTasks).secondArg));
      end if;
      listOfWarehouseBuffer.InsertToWarehouse(CalculateTask(listOfTask(actualSizeOfTasks)));

    end loop;     
  end Workertype;
    
-- ***********************************************
-- Procedure which print actual state of warehouse   
-- *********************************************** 
   procedure printWarehouseElements  is
   begin
      put_line("");put("Warehouse: {");
      warehouse_loop:
      for I in 0 .. actualSizeOfWarehouse loop
            exit warehouse_loop when listOfResultsInWarehouse(I) = 0;
            put(integer'image(listOfResultsInWarehouse(I)) &",");
      end loop warehouse_loop;
      put("}");put_line("");
   end printWarehouseElements;
   
-- *****************************************
-- Procedure which print actual tasks to do   
-- *****************************************
   procedure printTaskToDo  is
   begin
      put_line("");put("Task to do : [");
      task_loop:
      for I in 0 .. actualSizeOfTasks loop
            exit task_loop when listOfTask(I).firstArg = 0;
            put("{"&integer'image(listOfTask(I).firstArg) &","&integer'image(listOfTask(I).secondArg) &","&character'image(listOfTask(I).operation)&"}, ");
      end loop task_loop;
      put("]");put_line("");
   end printTaskToDo;
   
-- ************************************
-- Function to generate random numbers 
-- ************************************
  function randNumber ( n: in Positive) return Integer is
      subtype Rand_Range is Integer range 0 .. n;
      package Rand_Int is new Ada.Numerics.Discrete_Random(Rand_Range);
      use Rand_Int;
      gen : Rand_Int.Generator;
      ret_val: Rand_Range;
  begin
    Rand_Int.Reset(gen);
    ret_val := Random(gen);
  return ret_val;
  end;
     

end functions;
