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
}

var listOfTaskToDo = make(chan task, config.TaskSize)
var warehouse = make(chan string, config.WarehouseSize)
var deceptive = false

func bossTask() {
	var operations = []string{"+", "-", "*"}
	for {
		s1 := rand.NewSource(time.Now().UnixNano())
		r1 := rand.New(s1)
		firstArg := r1.Intn(10000)
		secondArg := r1.Intn(10000)
		operation := operations[r1.Intn(3)]
		listOfTaskToDo <- task{firstArg, secondArg, operation}
		if deceptive{fmt.Println("Boss add new task: ", firstArg, operation, secondArg)}
		time.Sleep(time.Duration(config.TimeForNewTask) * time.Second)

	}
}

func worker(idWorker int) {

	for {
		task := <-listOfTaskToDo
		if deceptive{fmt.Println("[Worker ", idWorker, "] Operation to do : ", task.firstArg, task.operation, task.secondArg)}
		switch task.operation {
		case "+":{
				warehouse <- strconv.Itoa(task.firstArg + task.secondArg)
				time.Sleep(time.Duration(config.TimeReciveTaskForWorker) * time.Second)
			}
		case "-":{
				warehouse <- strconv.Itoa(task.firstArg - task.secondArg)
				time.Sleep(time.Duration(config.TimeReciveTaskForWorker) * time.Second)
			}

		case "*":{
				warehouse <- strconv.Itoa(task.firstArg * task.secondArg)
				time.Sleep(time.Duration(config.TimeReciveTaskForWorker) * time.Second)
			}

		}
	}
}

func client() {

	for {
		productToBuy := <-warehouse
		if deceptive {fmt.Println("Client bought product: ", productToBuy)}
		time.Sleep(time.Duration(config.TimeForBuy) * time.Second)

	}
}


func checkStatusOfWarehouse()  {

	var presentsAmountOfElements = len(warehouse)
	fmt.Println("Warehouse items: ", presentsAmountOfElements)
	counter := 0
	for {
		value, _ := <-warehouse
		warehouse<-value;
		if counter == presentsAmountOfElements {break}
		counter++
		fmt.Println("  ", value)
	}

}

func checkTaskToDo() {
	var presentsAmountOfElements = len(listOfTaskToDo)
	fmt.Println("Tasks to do: ", presentsAmountOfElements)
	counter := 0
	for {
		value, _ := <-listOfTaskToDo
		listOfTaskToDo <-value
		if counter == presentsAmountOfElements {break}
		counter++
		fmt.Println("  ", value)
	}
}
func main() {

	fmt.Println("Choose: deceptive mode/quiet mode  D/Q: ")

	var chosedMode string
	fmt.Scanln(&chosedMode)

	go bossTask()
	for i := 0; i < config.NumberOfWorkers; i++ {go worker(i + 1)}
	go client()

	if chosedMode == "D" {
		deceptive = true
		fmt.Scanln()

	} else if chosedMode == "Q" {

		for {
			fmt.Println("Choose ")
			fmt.Println("      1: to check warehouse ")
			fmt.Println("      2: to check task to do  ")
			fmt.Println("      3: to quit   ")

			fmt.Scanln(&chosedMode)
			if chosedMode == "1" {
				checkStatusOfWarehouse()
			}
			if chosedMode == "2" {
				checkTaskToDo()
			}
			if chosedMode == "3" {
				os.Exit(0)
			}
		}

	}
}
