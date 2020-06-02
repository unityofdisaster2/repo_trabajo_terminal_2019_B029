function results =  modulo_CAE(modelo, parametros)


for ii = 1:size(parametros, 1)
	modelo.param.set(parametros{ii, 1}, parametros{ii, 2});
end

%si ya existe un estudio solo se ejecuta y se grafica el grupo de graficas generado


% Para el caso que no existe un estudio asociado con el modelo
% se crea uno que corresponda al nombre seleccionado por el usuario

try
    std = modelo.study.create('std1');
    std.feature.create('stat', 'Stationary');
    
catch ME
    % Si no es la primera vez que se ejecuta el estudio sobre este modelo
    % solo se extrae el objeto que lo controla
    disp('ya existe un estudio. Se ejecutara con los nuevos parametros');
    std = modelo.study('std1');
end
std.run;


% Obtencion de maximos
u = mphmax(modelo, 'comp1.u', 'volume');
v = mphmax(modelo, 'comp1.v', 'volume');
w = mphmax(modelo, 'comp1.w', 'volume');
maxDesp = max([u v w]);


%creacion de grupo de graficas 

% grafica de deformacion o desplazamiento
try 
    pg = modelo.result.create('pg1', 'PlotGroup3D');
catch ME
    pg = modelo.result('pg1');
end

try 
    pg.feature.create('surf1', 'Surface');

    pg.feature('surf1').set('expr', 'solid.disp');

    pg.feature('surf1').create('def1', 'Deform');

    pg.feature.create('maxV1', 'MaxMinVolume');

    pg.feature('maxV1').set('expr', 'solid.disp');

    pg.feature('maxV1').create('def2', 'Deform');

catch ME
    disp('ya existen las caracteristicas del primer grupo de graficas');
end

pg.run;
figure;
mphplot(modelo,'pg1','rangenum',1,'view','auto');
% grafica de stress 
try
    pg2 = modelo.result.create('pg2', 'PlotGroup3D');
catch ME
    pg2 = modelo.result('pg2');
end

try
    pg2.feature.create('surf2', 'Surface');


    pg2.feature('surf2').create('def3', 'Deform');


    pg2.feature('surf2').set('expr', 'solid.sp1');

    pg2.feature.create('maxV2', 'MaxMinVolume');

    pg2.feature('maxV2').set('expr', 'solid.sp1');

    pg2.feature('maxV2').create('def4', 'Deform');
    
catch ME
    disp('ya existen las caracteristicas del segundo grupo de graficas');
end
pg2.run;
figure;
mphplot(modelo,'pg2','rangenum',1,'view','auto');

% Creacion de tablas para extraer maximo desplazamiento y maxima presion

tblObj = mphtable(modelo,'mm1');
tabla = tblObj.data;

maxDesp = tabla(end,end);


tblObj = mphtable(modelo,'mm2');
tabla = tblObj.data;

maxPr = tabla(end,end);


results = [maxDesp maxPr];

end
