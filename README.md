## Toolkit
Icarus Verilog version 11.0, logisim-evolution-3.8.0

## Variant
Logisim normal, structural Verilog normal, behavioral Verilog normal

# Description
## Task and Input Processing Description
You need to model a stack with 5 cells in Logisim and Verilog in two variants: structural and behavioral. The stack is controlled by the commands nop, push, pop.

| Code | Command | Explanation                                                                                   |
|------|---------|----------------------------------------------------------------------------------------------|
| 0    | nop     | No operation; nothing happens.                                                               |
| 1    | push    | The top of the stack shifts to the next cell, then the specified value is written to the current cell. |
| 2    | pop     | Remove the value from the top cell of the stack: output it and shift the top of the stack. (The values in the cells remain unchanged.) |
| 3    | get     | Get the value from a cell based on an index relative to the top of the stack.              |

The index is provided as a three-bit number and should be used modulo 5.

One cell stores 4 bits. The stack has no "occupied" state (occupied/free). This means that by default, the cells contain zeros.

There should also be an input for initialization (RESET) – asynchronously resets the circuit to its initial state and clears the state of internal memory. This means that all memory (not just stack cells) must be reset to zero, regardless of the CLK value.

CLK synchronization should operate on a high level. For the circuit in Logisim, this means that the command is executed when CLK=1, and if CLK=0 is held, nothing happens regardless of the input. Each operation should be executed in one clock cycle, but the correct sequence of actions must be followed as described in the table above.

In Logisim, I implemented the stack's top using memory (a three-bit cell holds the pointer to the top of the stack). The physical top of the stack shifts up or down (for push and pop, respectively) when CLK=1, PUSH or POP is received, followed by CLK=0 (regardless of the input states unless it's RESET). For PUSH, the value is written to the top of the stack as it was before, and for POP, I calculate the downward shift using a logic circuit and output the value from the cell based on the previously saved pointer minus 1.

From an implementation perspective in behavior, it looks like this. While it's not a pretty construct for programming, it helps in the circuit to avoid signal races:
```
result = memory_cell[(pointer + 4) % 5];
pointer = (pointer + 4) % 5;
```

In Logisim, I also need to work with input-output: there’s one wire connected to both inputs and outputs. Since reading and writing cannot happen simultaneously, this is possible. To avoid signal conflicts, I used transistors and high-impedance states to "cut off" unnecessary wires currently connected to the input-output wire. The conditions also specify that when reading, high-impedance should be set at the inputs, and when writing, the same as at the outputs.

*In general, I've already described the most complex parts.*

## Logisim
***stack*** - the main circuit where I only process signals and connect the inputs to the stack interface circuit (for easier debugging). I placed CMOS transistors to allow or prevent data from passing through the wire on the left. CMOS consists of pairs of field-effect transistors: NMOS and PMOS. NMOS transistors conduct current when a high voltage level (logical one) is applied to their gate. Conversely, when the input signal for PMOS is high, it does not conduct. Thus, in my circuit, they are either both open and current flows, or both are closed, resulting in a high-impedance state – you can imagine that we cut the wires and they are temporarily gone.

1 ***stack_interface*** - a schematic description of the stack. It includes three subcircuits: a memory module with stack cells, command processing, and a pointer to the top of the stack.

1.1 ***big_memory*** - memory module. I made it according to the notes. There is a read/write state and a requested address to work with five memory cells (stack cells). If reading occurs, the requested data appears at the output (OUT_DATA). I also added outputs for the state of the cells. Originally, they were not included, but they were requested in the main circuit.

1.2 ***parser*** - command processing. The inputs process CLK, command, pointer to the top, and index from the main inputs to determine how to interact with the memory module: reading/writing, address. If the command is not PUSH but POP or GET, I need to first calculate which address to access. As I mentioned, I made a workaround for the downward shift using a logic circuit.

1.3 ***get_stack_pointer*** - managing the pointer to the top of the stack. The top of the stack only changes with push or pop, so I only deal with those commands. D flip-flops are used here to move the pointer after CLK=1 and push/pop. The SHIFT_FLAG tunnel indicates that it’s time to move the pointer. To update the pointer, I use two 3-bit memory cells and place a logic circuit between them to shift up or down. You cannot write to one of them, as it would cause a short circuit (it might have been solvable with transistors, but I didn't think of that initially).

1.3.1 ***D_trigger*** - a trigger from which I create the control for shifting the pointer and memory cell. Its main property: if CLK=1 and some bit is at D, that same bit will remain at Q after CLK=0 regardless of D's state until CLK=1 comes again.

1.3.1.1 ***RS_trigger*** - a trigger to create a D flip-flop. CLK ensures that changes occur only at CLK=1. The POR element acts as a bug protection for Logisim.

| R (Reset) | S (Set)  | Q (Output) | Q' (Inverted Output) |
|-----------|----------|------------|-----------------------|
| 0         | 0        | Q_prev     | Q'_prev               |
| 0         | 1        | 1          | 0                     |
| 1         | 0        | 0          | 1                     |
| 1         | 1        | Unpredictable | Unpredictable       |

1.3.2 ***memory_cell3*** - a 3-bit memory cell, simply three D flip-flops with shared triple input and output. ***memory_cell4*** - similarly.

1.3.4 ***mod5_calculate*** - a logic circuit for subtracting 1 or adding 1 to the input number modulo 5.

1.3.4.1 ***mod_5*** - a logic circuit for taking a three-bit number modulo 5.

1.2.1 ***shifter*** - calculating (4 - index) mod 5.

1.2.2 ***shift_pointer*** - shifting down by one if a pop command is received, for my workaround.

1.2.3 ***count_sum_mod5*** - summing two three-bit numbers modulo 5.

1.2.4 ***select_index*** - selecting the index to be sent to the memory module as the requested address. Here, a DNF (Disjunctive Normal Form) is used (I often use it as a substitute for if statements in programming).

1.1.1 ***demux*** - a demultiplexer that synchronizes with the memory cells to indicate where to start writing data. It converts a three-bit number into a signal of 1 on one of the corresponding wires from five if CLK=1.

1.1.1.1 ***decoder*** - converts a three-bit number into a signal of 1 on one of the corresponding wires from five.

1.1.2 ***mux4*** - a quadruple multiplexer that returns the value of a four-bit cell with the corresponding index. It is made from four regular multiplexers.

1.1.2.1 ***mux*** - a multiplexer that returns the value from the input with the corresponding index. This also uses DNF.

## Structural Verilog
Analogous to the Logisim circuit, except without the POR element and requiring the implementation of logical elements not limited to 2 inputs and CMOS for 4 wires. I also created separate modules for command parsing for convenience. The smartest decision compared to last time was to debug separate modules with testbenches because my attention span is insufficient to spot a typo.

The concept of CMOS is the same as in Logisim: if p_ctrl, we pass data; if n_ctrl, we enter a high-impedance state.
```verilog
module cmos4(
    inout wire[3:0] I_DATA,  
    output wire[3:0] O_DATA,
    input wire p_ctrl,
    input wire n_ctrl
    );
    cmos p0(O_DATA[0], I_DATA[0], p_ctrl, n_ctrl);
    cmos p1(O_DATA[1], I_DATA[1], p_ctrl, n_ctrl);
    cmos p2(O_DATA[2], I_DATA[2], p_ctrl, n_ctrl);
    cmos p3(O_DATA[3], I_DATA[3], p_ctrl, n_ctrl);
endmodule
``` 

## Behavioral Verilog
In Verilog, everything is done in modules rather than functions or classes. The assignment declared the module to work with.
```verilog
module stack_behaviour_normal(
    inout wire

[3:0] IO_DATA, 
    input wire RESET, 
    input wire CLK, 
    input wire[1:0] COMMAND,
    input wire[2:0] INDEX
    );
```

Next comes its description. Here’s how to declare the main variables: the stack memory, the pointer to the top of the stack, and variable ```i``` for the loop. integer is like int in C++; Verilog also has int, but not in all versions. reg is a set of bits that can have 4 states: 0, 1, z (high impedance), and x (undefined).
```verilog
reg[3:0] memory_cell[4:0];
integer pointer;
integer i;
```

Declaring the output register and initializing it to high impedance:
```verilog
reg[3:0] result = 4'bzzzz;
```

Connecting the wire to the register:
```verilog
assign IO_DATA = result;
```

This logic means that when CLK=0, a high-impedance state should always be output. RESET=1 resets the values in the memory cells asynchronously (independently of CLK), and when CLK=1, the incoming command should be executed. I divided the blocks based on whether the incoming data affects the variables or the output.
```verilog
always @(!CLK) begin
    result = 4'bzzzz;
end
always @(CLK or RESET) begin
    if (RESET) begin
    ...
    end
    else if (CLK) begin
    ...
    end
end
```

The always operators are executed continuously during simulation every time at least one of its sensitivity list arguments changes to 1 (true). Input signal names are separated by the keyword or or the symbol , . I used ```or```, and the sensitivity list is what’s in parentheses. The essence of always is that processing does not occur sequentially like it typically does in loops in C++, but continuously – as long as the simulation is running.


## Инструментарий
Icarus Verilog version 11.0, logisim-evolution-3.8.0

## Вариант
logisim normal, structural verilog normal, behavior verilog normal

# Описание
## Задача и описание обработки входов
Необходимо смоделировать стек на 5 ячейках в Logisim и Verilog в двух вариантах: структурный и поведенческий. Стек упраляется командами nop, push, pop
| Код | Команда | Пояснение                                                                                   |
|-----|---------|---------------------------------------------------------------------------------------------|
| 0   | nop     | Нет операции, ничего не происходит.                                                         |
| 1   | push    | Вершина стека смещается на следующую ячейку, затем в текущую ячейку записывается указанное значение. |
| 2   | pop     | Снять значение ячейки с вершины стека: подать его на выход и сместить вершину стека. (Значения в ячейках не меняются.) |
| 3   | get     | Получить значение ячейки по индексу относительно вершины стека.                           |

Индекс подаётся как трёхбитное число, его нужно использовать по модулю 5

Одна ячейка хранит 4 бита. У стека нет состояния "занятости" (занято/свободно). Это значит, что по умолчанию в ячейках записаны нули

Отдельно должен быть вход для инициализации (RESET) – асинхронно переводит схему в начальное состояние и обнуляет состояние внутренней памяти. Это значит, что вся память (не только ячейки стека) должны быть переведены в нулевое состояние, притом независимо от значения CLK

Синхронизация CLK должна работать по высокому уровню. Для схемы в Logisim это значит, что команда исполняется засчёт CLK=1 и если просто держать значение CLK=0, то ничего не происходит независимо от входа. Каждая операция должна быть исполнена за один такт, но при этом нужно соблюсти правильную последовательность действий, как это описано в таблице сверху

В Logisim я это сделала немного хитро. Вершину стека я реализовала через память (трёхбитная ячейка хранит указатель на вершину стека). Физически вершина стека смещается вверх или вниз (при push и pop соответственно), когда пришло CLK=1, PUSH или POP, а потом CLK=0 (независимо от того, в каком состоянии находятся входы, если это не RESET). Для PUSH запись значения идёт в вершину стека, которая сохранилась до этого, а для POP я считаю сдвиг вниз с помощью логической схемы и вывожу значение ячейки по сохранившемуся до этого указателю минус 1

С точки зрения реализации в behavior это бы выглядело так. Для программирования это некрасивая конструкция, а в схеме удобно, потому что это помогает избежать гонки сигналов
```
result = memory_cell[(pointer + 4) % 5];
pointer = (pointer + 4) % 5;
```

В Logisim также требуется работать со входо-выходами: есть один провод, который подключён и к входам, и к выходам. Поскольку чтение и запись не могут идти одновременно, это возможно. Чтобы не было конфликта сигналов, я использовала транзисторы и высокоимпедансное состояние, чтобы "отрезать" ненужные в текущий момент провода, подключённые к проводу входо-выходов. В условии также сказано, что при чтении на входах должно быть выставлено высокоимпедансное состояние, а при записи на выходах то же самое, что на входах

*в общем-то самые сложные вещи я уже описала*

## Logisim
***stack*** - основная схема, где я только обрабатываю сигналы и подключаю входы в интерфейсную схему стека (для простоты отладки). Я поставила cmos транзисторы, чтобы пропускать или не пропускать данные, которые поступили по проводу слева. CMOS состоит из пар полевых транзисторов: NMOS и PMOS. NMOS транзистор проводит ток, когда на его затвор подается высокий уровень напряжения (логическая единица). Когда у PMOS входной сигнал высокий, он наоборот не проводит. То есть на моей схеме они либо оба открыты и ток проходит, либо оба закрыты и получается высокоимпедансное состояние - можно представить, что мы отрезали провода и их временно нет

1 ***stack_interface*** - схема описания стека. В ней есть три подсхемы: модуль памяти с ячейками стека, обработка команд, указатель на вершину стека

1.1 ***big_memory*** - модуль памяти. Я его сделала по конспекту. Есть состояние чтения/записи и запрашиваемый адрес, чтобы работать с пятью ячейками памяти (ячейки стека). Если происходит чтение, то на выходе получается то что попросили прочитать (OUT_DATA). Ещё добавила выходы состояния ячеек. В оригинале их нет, но их попросили сделать в схеме main

1.2 ***parser*** - обработка команд. На входах обрабатываются CLK, команда, указатель на вершину и индекс с основных входов, чтобы определить, как нужно обращаться к модулю памяти: чтение/запись, адрес. Если команда не PUSH, а POP или GET, то перед этим ещё нужно посчитать, к какому адресу обратиться. Как я уже говорила, я сделала костыль перехода на 1 вниз с помощью логической схемы

1.3 ***get_stack_pointer*** - управление указателем на вершину стека. Вершина стека меняется только при push или pop, поэтому я разбираюсь только с этими командами. Тут стоят D-триггеры, чтобы получилось двигать указатель после CLK=1 и push/pop. Туннель SHIFT_FLAG показывает, что пришло время двигать указатель. Для обновления указателя я использую две 3-битные ячейки памяти и между ними ставлю логическую схему для сдвига вверх или вниз. В одну класть нельзя, а то будет короткое замыкание (наверное, можно было решить транзисторами, но я не подумала об этом сразу)

1.3.1 ***D_trigger*** - триггер, из которого я делаю управление сдвигом указателя и ячейки памяти. Его главное свойство: если пришло CLK=1 и какой-то бит на D, то этот же бит останется на Q после CLK=0 независимо от состояния D до тех пор пока снова не придёт CLK=1 

1.3.1.1 ***RS_trigger*** - триггер, чтобы сделать D-триггер. CLK делает так, что изменение происходит только при CLK=1. Элемент POR стоит как защита от багов Logisim

| R (Сброс) | S (Установка)  | Q (Выход) | Q' (Инверсный выход) |
|-----------|---------------|-----------|-----------------------|
| 0         | 0             | Q_prev    | Q'_prev               |
| 0         | 1             | 1         | 0                     |
| 1         | 0             | 0         | 1                     |
| 1         | 1             | Непредсказуемо | Непредсказуемо     |

1.3.2 ***memory_cell3*** - ячейка памяти на 3 бита, просто три D-триггера, только с общими тройными входом и выходом. ***memory_cell4*** - аналогично

1.3.4 ***mod5_calculate*** - логическая схема для вычитания 1 или сложения с 1 входного числа по модулю 5 

1.3.4.1 ***mod_5*** - логическая схема взятия трёхбитного числа по модулю 5

1.2.1 ***shifter*** - подсчёт (4 - index) mod 5

1.2.2 ***shift_pointer*** - сдвиг на единицу вниз, если пришёл pop, для моего костыля

1.2.3 ***count_sum_mod5*** - сумма двух трёхбитных чисел по модулю 5

1.2.4 ***select_index*** - выбор индекса, который будет отправлен модулю памяти как запрашиваемый адрес. Здесь используется ДНФ (я вообще часто ей пользуюсь как заменой if в программировании)

1.1.1 ***demux*** - демультиплексор, отвечает за синхронизацию к ячейкам памяти, чтобы указать на начало записи данных. Он преобразует трёхбитное число в сигнал 1 на одном из соответствующих проводов из пяти, если CLK=1

1.1.1.1 ***decoder*** - преобразует трёхбитное число в сигнал 1 на одном из соответствующих проводов из пяти

1.1.2 ***mux4*** - четверной мультиплексор, по индексу возвращает значение четырёхбитной ячейки с этим индексом. Он сделан из четырёх обычных мультиплексоров

1.1.2.1 ***mux*** - мультиплексор, по индексу возвращает значение входа с этим же номером. Тут тоже ДНФ

## Structural Verilog
Аналогично схеме в Logisim, только нет элемента POR и нужно самостоятельно реализовать логические элементы не от 2 входов и cmos для 4 проводов. Ещё я сделала отдельные модули парсинга команд для удобства. Самое умное соображение по сравнению с прошлым разом - отладить тестбенчами отдельные модули, потому что моей концентрации внимания не хватает, чтобы найти опечатку

Смысл CMOS такой же как в Logisim: если p_ctrl, то данные пропускаем, а если n_ctrl, то высокоимпедансное состояние
```
module cmos4(
    inout wire[3:0] I_DATA,  
    output wire[3:0] O_DATA,
    input wire p_ctrl,
    input wire n_ctrl
    );
    cmos p0(O_DATA[0], I_DATA[0], p_ctrl, n_ctrl);
    cmos p1(O_DATA[1], I_DATA[1], p_ctrl, n_ctrl);
    cmos p2(O_DATA[2], I_DATA[2], p_ctrl, n_ctrl);
    cmos p3(O_DATA[3], I_DATA[3], p_ctrl, n_ctrl);
endmodule
```

## Behavior Verilog
В Verilog всё делается не из функций или классов, а из модулей. В задании объявили модуль, с которым нужно работать
```
module stack_behaviour_normal(
    inout wire[3:0] IO_DATA, 
    input wire RESET, 
    input wire CLK, 
    input wire[1:0] COMMAND,
    input wire[2:0] INDEX
    );
```

Далее идёт его описание. Так выглядит объявление основных переменных: память стека, указатель на вершину стека и переменная ```i``` для цикла. integer - это как int в C++, в Veriloge тоже есть int, но не во всех версиях. reg - это набор битов, у которых может быть 4 состояния: 0, 1, z (высокоимпедансное) и x (неопределённое)
```
reg[3:0] memory_cell[4:0];
integer pointer;
integer i;
```

Объявление регистра вывода и инициализация высокоимпедансным состоянием
```
reg[3:0] result = 4'bzzzz;
```

Присоединение провода к регистру
```
assign IO_DATA = result;
```

Эта логика значит, что при CLK=0 нужно всегда выводить высокоимпедансное состояние, RESET=1 сбрасывает значения в ячейках памяти асинхронно (независимо от CLK), при CLK=1 нужно выполнять поступившую команду. Я разделила блоки по принципу влияют ли пришедшие данные на переменные или вывод
```
always @(!CLK) begin
    result = 4'bzzzz;
end
always @(CLK or RESET) begin
    if (RESET) begin
    ...
    end
    else if (CLK) begin
    ...
    end
end
```

Операторы always выполняются непрерывно во время моделирования каждый раз, когда хотя бы один из его аргументов в списке чувствительности меняет значение на 1 (true). Имена входных сигналов разделяются ключевым словом or или символом , . Я использовала ```or```, список чувствительности - это то что в скобках. Суть always в том что обработка происходит не подряд как это привычно в циклах в языке C++, а всегда - пока запущено моделирование

