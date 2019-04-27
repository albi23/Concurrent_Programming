package  functions is

 
 --Thread that stimulate boss in company
 task type BossTask is 
    entry Start;
 end BossTask;
 
 --Threads that stimulate employees
 task  type Workertype  is
   entry go( nrWorkers : Integer);
 end Workertype;
 
 -- Type of task to do by employee  
 type Tasks is record
   	 firstArg   : Integer;
   	 secondArg  : Integer;
     operation  : Character;
 end record;
 
 
 -- Task who is responsible for add and remove elements from list of tasks
 task type TasksListBuffer is
     entry Insert ( newTask : in Tasks);
     entry Remove ( idWorker : in Integer);    
 end TasksListBuffer;

 -- Task who is responsible for add and remove elements from warehouse
 task type WarehouseBuffer is
    entry InsertToWarehouse ( newResult : in Integer);
    entry RemoveFromWarehouse ;    
 end WarehouseBuffer;
 

  -- Task who is responsible for symulation client bought products from warehouse
  task type Client is  end Client;

 function randNumber ( n: in Positive) return Integer;
 function CalculateTask(x : in Tasks) return Integer ;
 procedure printWarehouseElements;
 procedure printTaskToDo;

  
end functions;