
package  functions is
 
 --Thread that stimulate boss in company
 task type BossTask is 
    entry Start;
 end BossTask;
 
 --Threads that stimulate employees
 task  type Workertype  is
   entry go( nrWorkers : Integer ; p : Boolean);
 end Workertype;
 
 -- Type of task to do by employee  
 type Tasks is record
   	 firstArg   : Integer;
   	 secondArg  : Integer;
     operation  : Character;
     result     : Integer;
 end record;
  
 type Machine is record
      busy      : Boolean;
 end record;
 
 type WorkerInfo is record
    patient     : Boolean;
    doneTasks   : Integer;
 end record;
  
  task  type addingMachine  is
    entry startAdding( machine : Integer);
    entry addTask(taskToDo : Tasks);
    entry Get_Result (Result : out Tasks);
  end addingMachine;
  
  task  type multiplyMachine  is
      entry startMultiply( machine : Integer);
      entry multiplyTask(taskToDo : Tasks);
      entry Get_Result (Result : out Tasks);
  end multiplyMachine;
 
 -- Task who is responsible for add and remove elements from list of tasks
 task type TasksListBuffer is
     entry Insert ( newTask : in Tasks);
     entry Remove (  Result : out Tasks);    
 end TasksListBuffer;

 -- Task who is responsible for add and remove elements from warehouse
 task type WarehouseBuffer is
    entry InsertToWarehouse ( newResult : in Integer);
    entry RemoveFromWarehouse ;    
 end WarehouseBuffer;
 

  -- Task who is responsible for symulation client bought products from warehouse
  task type Client is  end Client;

 function randNumber ( n: in Positive) return Integer;
 procedure startAddingMachines;
 procedure startMultiplyMachines;
 procedure startWorkers;
 procedure printWarehouseElements;
 procedure printTaskToDo;
 procedure printWorkersStats;

  
end functions;