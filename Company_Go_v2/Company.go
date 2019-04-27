package main

import (
	config "./configuration"
	"fmt"
	"math/rand"
	"os"
	"strconv"
	"time"
)

type task struct {
	firstArg  int
	secondArg int
	operation string
	result    string
}

type writeTask struct {
	task task
	resp chan bool
}

type readTask struct {
	request bool
	resp    chan task
}

type writeWarehouse struct {
	result   chan bool
	doneTask string
}

type readWarehouse struct {
	request  bool
	response chan string
}

type Machine struct {
	taskResponse chan task
	taskToDo     chan *task
	busy         bool
}

type Worker struct {
	patient  bool
	doneTask int
}

var workersStats = make([]Worker, config.NumberOfWorkers)
var listOfTasks = make([]task, 0)
var writeTaskChan = make(chan *writeTask)
var readTaskChan = make(chan *readTask)
var warehouseList = make([]string, 0)
var writeWarehouseChan = make(chan *writeWarehouse)
var readWarehouseChan = make(chan *readWarehouse)
var MachineChan = make([]Machine, config.NumberOfAddingMachines+config.NumberOfMultiplyMachines)
var deceptive = false

func bossTask() {
	var operations = []string{"+", "*"}
	for {
		s1 := rand.NewSource(time.Now().UnixNano())
		r1 := rand.New(s1)
		firstArg := r1.Intn(10000)
		secondArg := r1.Intn(10000)
		operation := operations[r1.Intn(1)]
		toDoTask := &writeTask{
			task: task{firstArg, secondArg, operation, ""},
			resp: make(chan bool)}
		writeTaskChan <- toDoTask
		response := <-toDoTask.resp
		if deceptive && response {
			fmt.Println("\u001b[32m [ Boss ] add new task: ", firstArg, operation, secondArg, " \u001B[0m")
		}
		time.Sleep(time.Duration(config.TimeForNewTask) * 400 * time.Millisecond)

	}
}

func worker(idWorker int, patient bool) {

	for {
		patient := patient
		takenTask := &readTask{request: true, resp: make(chan task)}
		readTaskChan <- takenTask
		task := <-takenTask.resp
		if deceptive && task.firstArg != 0 {
			fmt.Println("\u001b[34m [Worker ", idWorker, "] Operation to do : ", task.firstArg, task.operation, task.secondArg, " \u001B[0m")
		}

		s1 := rand.NewSource(time.Now().UnixNano())
		r1 := rand.New(s1)

		switch task.operation {
		case "+":
			{
				var machine = r1.Intn(config.NumberOfAddingMachines)
				if patient {
					//fmt.Println("[Worker ",idWorker,"] is patient = ",patient," and want to do MachineChan[",machine,"]")
					MachineChan[machine].taskToDo <- &task
				} else {
					for {
						machine = r1.Intn(config.NumberOfAddingMachines)
						//fmt.Println("Worker ",idWorker,"  try choose ",machine)
						if MachineChan[machine].busy == false {
							//fmt.Println("[Worker ",idWorker,"] is patient = ",patient," and want to do MachineChan[",machine,"]")
							MachineChan[machine].taskToDo <- &task
							break
						} else {
							time.Sleep(time.Duration(config.TimeForWaitingImpatient) * time.Microsecond)
						}
					}
				}
				//fmt.Println("Waiting for response worker := ",idWorker)
				resultTask := <-MachineChan[machine].taskResponse
				newElement := &writeWarehouse{result: make(chan bool), doneTask: resultTask.result}
				writeWarehouseChan <- newElement
				<-newElement.result
				//fmt.Println("Done Worker ",idWorker,"  ", resultTask.firstArg," + ",resultTask.secondArg)
				workersStats[idWorker-1].doneTask++
				time.Sleep(time.Duration(config.TimeReceiveTaskForWorker) * time.Second)
			}
		case "*":
			{
				var machine = r1.Intn(config.NumberOfMultiplyMachines) + config.NumberOfAddingMachines
				if patient {
					//fmt.Println("[Worker ",idWorker,"] is patient = ",patient," and want to do MachineChan[",machine,"]")
					MachineChan[machine].taskToDo <- &task
				} else {
					for {
						machine = r1.Intn(config.NumberOfMultiplyMachines) + config.NumberOfAddingMachines
						//fmt.Println("Worker ",idWorker,"  try choose ",machine)
						if MachineChan[machine].busy == false {
							//fmt.Println("[Worker ",idWorker,"] is patient = ",patient," and want to do MachineChan[",machine,"]")
							MachineChan[machine].taskToDo <- &task
							break
						} else {
							time.Sleep(time.Duration(config.TimeForWaitingImpatient) * time.Microsecond)
						}
					}
				}
				resultTask := <-MachineChan[machine].taskResponse
				newElement := &writeWarehouse{result: make(chan bool), doneTask: resultTask.result}
				writeWarehouseChan <- newElement
				<-newElement.result
				workersStats[idWorker-1].doneTask++
				time.Sleep(time.Duration(config.TimeReceiveTaskForWorker) * time.Second)
			}
		}
	}
}

func addingMachine(idMachine int) {

	for {

		for toDo := range MachineChan[idMachine-1].taskToDo {
			MachineChan[idMachine-1].busy = true
			time.Sleep(time.Duration(config.TimeAddingMachine) * time.Second)
			if deceptive {
				fmt.Println("\u001b[35m [Machine ", idMachine, "] is doing ", toDo.firstArg, " + ", toDo.secondArg, " \u001B[0m")
			}
			result := strconv.Itoa(toDo.firstArg + toDo.secondArg)
			MachineChan[idMachine-1].taskResponse <- task{toDo.firstArg, toDo.secondArg, toDo.operation, result}
			MachineChan[idMachine-1].busy = false

		}

	}
}

func multiplyMachine(idMachine int) {

	for {
		for toDo := range MachineChan[idMachine-1].taskToDo {
			MachineChan[idMachine-1].busy = true
			time.Sleep(time.Duration(config.TimeMultiplyMachine) * time.Second)
			if deceptive {
				fmt.Println("\u001b[35m [Machine ", idMachine, "] is doing ", toDo.firstArg, " * ", toDo.secondArg, " \u001B[0m")
			}
			result := strconv.Itoa(toDo.firstArg * toDo.secondArg)
			MachineChan[idMachine-1].taskResponse <- task{toDo.firstArg, toDo.secondArg, toDo.operation, result}
			MachineChan[idMachine-1].busy = false
		}
	}
}

func client() {

	for {
		productToBuy := &readWarehouse{request: true, response: make(chan string)}
		readWarehouseChan <- productToBuy
		if deceptive {
			fmt.Println("\u001b[31m [Client ] bought product: ", <-productToBuy.response, " \u001B[0m")
		} else {
			<-productToBuy.response
		}
		time.Sleep(time.Duration(config.TimeForBuy) * time.Second)

	}
}

func checkStatsOfWorkers() {

	for i := 0; i < len(workersStats); i++ {
		fmt.Println("\u001b[36m [Worker", i+1, "]  patient =", workersStats[i].patient, " done tasks : ", workersStats[i].doneTask, " \u001B[0m")
	}
}
func checkStatusOfWarehouse() {
	fmt.Println("\u001b[36m Warehouse: ", warehouseList, "\u001B[0m")
}
func checkTaskToDo() {
	fmt.Println("\u001b[36m Tasks to do: ", listOfTasks, "\u001B[0m")
}
func taskController() {

	for {
		select {

		case task := <-taskAddGuard(len(listOfTasks) < config.TaskSize, writeTaskChan):
			listOfTasks = append(listOfTasks, task.task)
			task.resp <- true

		case takenTask := <-taskGetGuard(len(listOfTasks) >= 1, readTaskChan):
			takenTask.resp <- listOfTasks[0]
			listOfTasks = listOfTasks[1:]
		}

	}
}
func warehouseController() {

	for {
		select {
		case newElement := <-warehouseAddGuard(len(warehouseList) < config.WarehouseSize, writeWarehouseChan):
			warehouseList = append(warehouseList, newElement.doneTask)
			newElement.result <- true

		case takeElement := <-warehouseGetGuard(len(warehouseList) >= 1, readWarehouseChan):
			takeElement.response <- warehouseList[0]
			warehouseList = warehouseList[1:]
		}
	}
}
func warehouseAddGuard(b bool, c chan *writeWarehouse) chan *writeWarehouse {
	if !b {
		return nil
	}
	return c
}
func warehouseGetGuard(b bool, c chan *readWarehouse) chan *readWarehouse {
	if !b {
		return nil
	}
	return c
}
func taskAddGuard(b bool, c chan *writeTask) chan *writeTask {

	if !b {
		return nil
	}
	return c
}
func taskGetGuard(b bool, c chan *readTask) chan *readTask {

	if !b {
		return nil
	}
	return c
}

func main() {

	fmt.Println("Choose: deceptive mode/quiet mode  D/Q: ")

	var chosedMode string
	fmt.Scanln(&chosedMode)

	go taskController()
	go warehouseController()
	go bossTask()
	for i := 1; i <= config.NumberOfAddingMachines+config.NumberOfMultiplyMachines; i++ {
		MachineChan[i-1] = Machine{}
		MachineChan[i-1].taskResponse = make(chan task)
		MachineChan[i-1].taskToDo = make(chan *task)
		MachineChan[i-1].busy = false
	}
	for i := 1; i <= config.NumberOfAddingMachines; i++ {
		go addingMachine(i)
	}
	for i := 1; i <= config.NumberOfMultiplyMachines; i++ {
		go multiplyMachine(i)
	}

	for i := 0; i < config.NumberOfWorkers; i++ {
		s1 := rand.NewSource(time.Now().UnixNano())
		r1 := rand.New(s1)
		var patient = true
		if r1.Float32() <= 0.5 {
			patient = false
		}
		workersStats[i].patient = patient
		go worker(i+1, patient)
	}
	go client()

	if chosedMode == "D" {
		deceptive = true
	} else if chosedMode == "Q" {

		for {
			fmt.Println("Choose ")
			fmt.Println("      1: to check warehouse ")
			fmt.Println("      2: to check task to do  ")
			fmt.Println("      3: to check workers stat  ")
			fmt.Println("      4: to quit   ")

			fmt.Scanln(&chosedMode)
			if chosedMode == "1" {
				checkStatusOfWarehouse()
			}
			if chosedMode == "2" {
				checkTaskToDo()
			}
			if chosedMode == "3" {
				checkStatsOfWorkers()
			}
			if chosedMode == "4" {
				os.Exit(0)
			}
		}

	}

	fmt.Scanln()

}
