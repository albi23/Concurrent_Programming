with  Ada.Text_IO;  use  Ada.Text_IO;
with Ada.Numerics.discrete_Random;
with configuration; use configuration;

package body functions is

 type Info is array (1 .. numbeOfEmployees) of WorkerInfo; 
  machineArr  : array (0 .. numbeOfAddingMachine +numbeOfMultiplyMachine -1) of Machine;
  addingArr   : array (0 .. numbeOfAddingMachine-1 ) of addingMachine;
  multiplyArr : array (0 .. numbeOfMultiplyMachine-1 ) of multiplyMachine;
  listOfTask  : array (0 .. maxSizeOfTasks) of Tasks;
  workerStat  : Info;
  workers     : array (1 .. numbeOfEmployees) of Workertype;
  listOfResultsInWarehouse : array(0 .. maxSizeOfWarehouse) of Integer;
  actualSizeOfTasks : Integer := 0;
  actualSizeOfWarehouse : Integer := 0;
  taskBuffer : TasksListBuffer;
  listOfWarehouseBuffer : WarehouseBuffer;
  clientOne : Client;


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
            accept  Remove (  Result : out Tasks) do
                actualSizeOfTasks := actualSizeOfTasks -1;
                Result := listOfTask(actualSizeOfTasks);
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
            put_line("[Client] bought : "&Integer'image(listOfResultsInWarehouse(actualSizeOfWarehouse)) & "");
        end if;
        delay 1.0*fastOfClient;
    end loop;
  end Client;
  
-- ***************************
-- Boss Simulation in company
-- ***************************
 task body BossTask is
    TaskToDo : Tasks;
    operations : array(0 .. 1) of Character;
 begin
    accept Start; 
     loop 
        operations := ('+','*');
        TaskToDo := (randNumber(rangeOfRandomNumber),randNumber(rangeOfRandomNumber),(operations(randNumber(1))),0);
        if(deceptive = true) then 
          put_line("[ Boss ] add new task: {"&Integer'image(TaskToDo.firstArg) &","&Integer'image(TaskToDo.secondArg) & "," & Character'image(TaskToDo.operation) &"}");
        end if;
        taskBuffer.Insert(TaskToDo);
        delay 1.0*delayBossTask;
      end loop;  
 end BossTask;  
 
 -- **************************************
 -- Simulation of Workers in the company
 -- **************************************
  task body  Workertype is 
    nr : Integer;
    doneTask : Tasks;
    toDoTask : Tasks;
    chosedMachine : Integer;
    patient : Boolean;
  begin
    accept go( nrWorkers : Integer ; p : Boolean) do 
           nr := nrWorkers;
           patient := p;       
    end go;     
    loop        
      delay 1.0*fastOfEmployees;
      taskBuffer.Remove(toDoTask);
      if(deceptive = true) then 
         put_line("[Worker" &Integer'image(nr) & "] Operation to do : " &Integer'image(toDoTask.firstArg) & Character'image(toDoTask.operation) &Integer'image(toDoTask.secondArg) & "");
      end if;
    
    if(toDoTask.operation = '+') then
    
        if(patient = true) then
            chosedMachine := randNumber(numbeOfAddingMachine - 1);
            addingArr(chosedMachine).addTask(toDoTask);
            addingArr(chosedMachine).Get_Result(doneTask); 
        else 
            chosedMachine := randNumber(numbeOfAddingMachine - 1);
            While_Loop:
                while machineArr(chosedMachine).busy = true loop
                    delay(Duration(TimeForWaitingImpatient));
                    chosedMachine := randNumber(numbeOfAddingMachine - 1);
                end loop While_Loop;
            addingArr(chosedMachine).addTask(toDoTask);
            addingArr(chosedMachine).Get_Result(doneTask);
        end if;
    else 
        if(patient = true) then
            chosedMachine := randNumber(numbeOfMultiplyMachine - 1);
            multiplyArr(chosedMachine).multiplyTask(toDoTask);
            multiplyArr(chosedMachine).Get_Result(doneTask); 
        else 
            chosedMachine := randNumber(numbeOfMultiplyMachine -1 );
            While_looop:
                while machineArr(chosedMachine + numbeOfAddingMachine).busy = true loop
                    delay(Duration(TimeForWaitingImpatient));
                    chosedMachine := randNumber(numbeOfMultiplyMachine - 1);
                end loop While_looop;
            multiplyArr(chosedMachine).multiplyTask(toDoTask);
            multiplyArr(chosedMachine).Get_Result(doneTask);
        end if;       
    end if;
  
      listOfWarehouseBuffer.InsertToWarehouse(doneTask.result);
      workerStat(nr).doneTasks := workerStat(nr).doneTasks +1;
    end loop;     
  end Workertype;
  
    
    
    --*****************************
    --  Simulation adding machines
    -- ****************************
   task body addingMachine is 
       idMachine : Integer;
       doneTask : Tasks;
     begin
      accept startAdding( machine : Integer) do 
--               put_line("Adding machine "&Integer'image(machine)&"  is running");
             idMachine := machine;
      end startAdding; 
        loop
          select
          
             when  machineArr(idMachine-1).busy = false =>
                accept addTask(taskToDo : Tasks) do
                    if(deceptive = true) then 
                        put_line("[Machine"& Integer'image(idMachine) & "] is doing "& Integer'image(taskToDo.firstArg)&" + "&Integer'image(taskToDo.secondArg));
                    end if;
                    machineArr(idMachine-1).busy := true;
                     delay 1.0*fastOfAddingMachine;
                    doneTask := taskToDo;
                    doneTask.result := taskToDo.firstArg + taskToDo.secondArg;
                --    Put_line("Zadanie zrobione");
                end addTask;
           or  
             accept Get_Result (Result : out Tasks) do
                    --   Put_line("Pobieram zadanie");
                       Result := doneTask;
                       machineArr(idMachine-1).busy := false;
             end Get_Result;   
          end select;  
        end loop;   
   end  addingMachine;   
   
    --*******************************
    --  Simulation multiply machines
    -- ******************************

      task body multiplyMachine is 
          idMachine : Integer;
          doneTask : Tasks;
        begin
         accept startMultiply( machine : Integer) do 
--                  put_line("Multiply machine "&Integer'image(machine)&"  is running");
                idMachine := machine;
         end startMultiply; 
           loop
             select
                when  machineArr(idMachine-1).busy = false => 
                   accept multiplyTask(taskToDo : Tasks) do
                    if(deceptive = true) then                    
                       put_line("[Machine"& Integer'image(idMachine) & "] is doing "& Integer'image(taskToDo.firstArg)&" * "&Integer'image(taskToDo.secondArg));
                    end if;   
                       machineArr(idMachine-1).busy := true;
                        delay 1.0*fastOfMultiplyMachine;
                       doneTask := taskToDo;
                       doneTask.result := taskToDo.firstArg * taskToDo.secondArg;
                   --    Put_line("Zadanie zrobione");
                   end multiplyTask;
              or  
                accept Get_Result (Result : out Tasks) do
                       --   Put_line("Pobieram zadanie");
                          Result := doneTask;
                          machineArr(idMachine-1).busy := false;
                end Get_Result;   
             end select;  
           end loop;   
      end  multiplyMachine; 


-- ***********************************************
-- Procedure tostart machines  adding machines   
-- ***********************************************
   procedure startAddingMachines is
   begin
       for I in Integer range 0 .. numbeOfAddingMachine-1 loop
              machineArr(I).busy := false;
              addingArr(I).startAdding(I+1);
       end loop; 
   end startAddingMachines;
   
      
-- ***********************************************
-- Procedure tostart machines  multiply machines   
-- ***********************************************   
   procedure startMultiplyMachines is
   begin
       for I in Integer range 0 .. numbeOfMultiplyMachine-1 loop
              machineArr(I+numbeOfAddingMachine).busy := false;
              multiplyArr(I).startMultiply(I+1+numbeOfAddingMachine);
       end loop; 
   end startMultiplyMachines;   
   
   
    procedure startWorkers is 
    patient : Boolean;
    begin
       for I in workers'Range loop
           patient := true;
           if (randNumber(9) < 5) then
              patient := false;
           end if;
            workerStat(I).patient := patient;
            workerStat(I).doneTasks := 0;
            workers(I).Go(I,patient);
       end loop;
    end startWorkers;
   
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

---**********************************
--- procedure to print worker sstat   
---**********************************

procedure printWorkersStats is
     infoArr  : Info;
begin 
    infoArr  := workerStat;
    
    for I in 1 .. numbeOfEmployees loop
        put_line("Worker "&Integer'image(I)& "  patient = "& Boolean'image(infoArr(I).patient) & "  done tasks : " &Integer'image(infoArr(I).doneTasks));
    end loop;
end printWorkersStats;

end functions;
