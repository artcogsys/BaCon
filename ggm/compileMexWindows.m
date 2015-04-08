lapacklib = fullfile(matlabroot,'extern','lib',computer('arch'),'microsoft',...
      'libmwlapack.lib');
blaslib = fullfile(matlabroot,'extern','lib',computer('arch'),'microsoft',...
  'libmwblas.lib');

mex('-v', '-largeArrayDims', 'gwishrnd_mex.cpp', blaslib, lapacklib);
mex('-v', '-largeArrayDims', 'ggm_cbf_mex.cpp', blaslib, lapacklib);