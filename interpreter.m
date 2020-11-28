function outs = interpreter(jsonObject)
    elementNames = fieldnames(jsonObject);
    disp(numel(elementNames));
	
    for ii = 1:numel(elementNames)
       modelo = mphopen('modelo_resorte.mph');
       
	   disp(jsonObject.(elementNames{ii}));
       disp(jsonObject.(elementNames{ii}).staticParams);
	   paramObj =jsonObject.(elementNames{ii}).parametros;
	   SW_params = cell(numel(paramObj),2);
	   disp('params');
       disp(paramObj(2));
	   for jj = 1:numel(paramObj)
		SW_params{jj,1} = paramObj(jj).name;
		SW_params{jj,2} = str2double(paramObj(jj).value);
	   end
	   disp(SW_params);
       modulo_CAD(modelo,SW_params);
    end
    %disp(jsonObject.resorte.parametros);
    outs = 1;
end
