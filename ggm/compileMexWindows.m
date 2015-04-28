lapacklib = fullfile(matlabroot,'extern','lib',computer('arch'),'microsoft',...
      'libmwlapack.lib');
blaslib = fullfile(matlabroot,'extern','lib',computer('arch'),'microsoft',...
  'libmwblas.lib');

mex('-v', '-largeArrayDims', 'gwishrnd_mex.cpp', blaslib, lapacklib);
mex('-v', '-largeArrayDims', 'ggm_cbf_mex.cpp', blaslib, lapacklib);

mex('-v', '-largeArrayDims', 'C:\Users\Max\Documents\CCNlabGit\trunk\ggm\ggm_cbf_exact_mex.cpp', blaslib, lapacklib);