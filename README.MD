

# Interpretation and Integration System from a Graphical Modeling Language To a MBSE Workflow 

This repository contains a collection of modules that connects either individually with models made in third party engineering tools via Matlab to automate testing tasks, or together into a system that interacts with the repository hosted in [unityofdisaster2/frontend-diagramas (github.com)][1] to receive an object with metadata which represents the content of a graphical diagram made with a modeling language. The enginnering tools suported are the following:

* SolidWorks. 
* Comsol Multiphysics. 
* Matlab/Simulink. 

# Technologies

Connection with engineering tools has been made using:

* Matlab R2019b.
* Comsol Multiphysics 5.5 With Matlab.
* SolidWorks 2019.

# Features

* TCP server that allows connections from the web application hosted in [unityofdisaster2/frontend-diagramas.com][1]
* Connection with SolidWorks to associate values received from a JSON object or manually to update global variables of a model and also reconstruct it with the new values. 
* Connection with Simulink to inject values to a previously made simulation model in order to execute it and generate a result composed of an array of data and time (if the model depends on time) or a static value. The result can be returned in a variable if it is executed manually or to the web application.
* Connection with COMSOL Multiphysics to inject values to a previously made analysis model in order to execute it and generate a result composed of a pair of values that represent maximum deformation and maximum pressure. 

# Setup

Clone or copy the content of this repository inside the default user work folder or inside the root of the current working folder. Furthermore, to ensure Matlab connection with the other tools it is necessary that they are running before executing any of the modules contained in this repository.

# Usage

If it is required, some of the modules can be used individually to test them or integrate into another project.  

### modulo_CAD

For individual usage of the module tagged as "modulo_CAD" you need to have SolidWorks and Comsol multiphysics running, and the model you want to work with open in both platforms. For this example has been chosen a simple cube model that has a global variable associate with its sides.

​											 ![](https://i.imgur.com/jeMjhI3.png) 

Cube model with an inicial side value of 100.  

To modify the value of global variables it's necessary to create a cell array of n*2 where n define the number of variables we want to update. Every entry has to be put as a pair of values composed of a string that defines a name and a number defining the new value. Below is an example using the side of the cube:

```matlab
% name of the comsol Multiphysics related with the cube
modelo = mphopen('modeloCubo.mph')

params = cell(1,2);

% name of the global variable
params{1, 1} = 'dimension';

% numeric value of the global variable 
params{1, 2} = 25;

% module execution (it doesn't return any result value)
modulo_CAD(modelo, params);

```

Originally "dimension" has a value of 100; if there aren't errors found during the execution, the update can be validated directly within SolidWorks as is showed down below:

![](https://i.imgur.com/q6aZt2g.png)

cube geometry after execution.  

### modulo_simulink 

For individual usage of the module tagged as "modulo_simulink" it is necessary to have a simulink model with blocks that make use of Matlab variables as is showed down below.  

![](https://i.imgur.com/vk3AipY.png)

Example model in Simulink that represents the differential equation of a simple pendulum.  

As you could see, the blocks that depend on Matlab variables are shown in red color because they are not defined yet. To give this variables a value it is necessary to create a cell array of n*2 where n define the number of variables where we want to inject a value. Every entry of the array has to be put as a pair of values composed of a string that defines a name and a number defining the new value. Below is an example code where some numeric values are injected to a Simulink model to calculate a differential equation:

```matlab
params = cell(8,2);
% gravity
params{1, 1} = 'g';
params{1, 2} = 10;
% mass
params{2, 1} = 'm';
params{2, 2} = 1;
% damping coeficient
params{3, 1} = 'c';
params{3, 2} = 0.2;
% length
params{4, 1} = 'L';
params{4, 2} = 1;
% final duration time of simulation
params{5, 1} = 'tFinal';
params{5, 2} = 45;
% steps from 0 to tFinal to get a more precise result
params{6, 1} = 'tStepMax';
params{6, 2} = 0.05;
% depending on the complexity of the model it could have 
% a variety of parameters, for this case a diferential equation is
% modeled so it needs values of initial conditions
params{7, 1} = 'theta0';
params{7, 2} = 0;

params{8, 1} = 'thetaDot0';
params{8, 2} = 0;

% name of the tested model
model_name = 'modelo_pendulo_individual';
% if depends on time, after the execution this module can return two arrays
% corresponding to time and data, if not, returns a simple numeric value
[tiempo, datos] = modulo_simulink(model_name, params);
```

If there aren't any errors during execution this module can return two kinds of value. If the Simulink model depends on time it will return two arrays composed of simulation time and resulting data in every step that has been configured. This could be used to see graphically the behavior of the model or for post-processing tasks. If there is no time dependency, a numeric vector of 1x1 is returned.

![](https://i.imgur.com/xoBCu1o.png)

plot showing the behavior of the pendulum with the given values.  

### modulo_CAE

For individual usage of the module tagged as "modulo_CAE" it is necessary to have COMSOL Multiphysics running and the model you want to work with open. Also, if the model is linked with a SolidWorks project it must be open as well. Although COMSOL Multiphysics has a lot of settings to determine physics analysis over a solid it has been chosen temporally to give support to physics for solid mechanics and a stationary study to get the maximum deformation and pressure given by an applied force. As future work has been considered to add more kinds of studies and physics to cover more use cases. Below is a code example where a force is applied to a spring:

```matlab
% model reference
modelo = mphopen('modelo_resorte4.mph');

params = cell(1, 2);
% force parameter
params{1, 1} = 'fuerza';
params{1, 2} = 50;
% execution of the module 
[displacement, pressure] = modulo_CAE(modelo, params);
```

As a result of the execution, two plots are shown to the user (that are shown down below) and also a pair of numeric values that represents the maximum displacement and maximum pressure.



![](https://i.imgur.com/DFyHp5S.png)

Maximum deformation over the spring with the given force.  





![](https://i.imgur.com/Wpktv6Q.png)

Maximum pressure over the spring with the given force.  



### Usage with the web application integration

For this use case, interaction with the modules mentioned above is automated and triggered when the user send a request from the frontend of the web application hosted in [unityofdisaster2/frontend-diagramas (github.com)][1] once the diagram or graphical model is finished. That request is taken by the backend hosted in [unityofdisaster2/backend-diagramas (github.com)][2] and send to a Matlab server through stream sockets. Once Matlab has caught the request it make use of a support module that interprets the data and distributes values to the corresponding module. Finally, all the numerical results are stored in a structure and send back to the user as a response. For running the Matlab TCP server you just need to call this function: 

```matlab
servidorMatlab();
```



# To-do

* Add more use cases for analysis module.
* Create an aditional module to connect values with Matlab local functions instead of limiting it to Simulink models.
* Find the possibility of returning graphs to the frontend instead of just numerical values.



[1]: https://github.com/unityofdisaster2/frontend-diagramas

[2]: https://github.com/unityofdisaster2/backend-diagramas

