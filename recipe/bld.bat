IF "%PY_VER%"=="3.5" (
	%PYTHON% -m pip install --no-deps https://pypi.org/packages/cp35/t/tensorflow/tensorflow-%PKG_VERSION%-cp35-cp35m-win_amd64.whl
)

IF "%PY_VER%"=="3.6" (
	%PYTHON% -m pip install --no-deps https://pypi.org/packages/cp36/t/tensorflow/tensorflow-%PKG_VERSION%-cp36-cp36m-win_amd64.whl
)
if errorlevel 1 exit 1
