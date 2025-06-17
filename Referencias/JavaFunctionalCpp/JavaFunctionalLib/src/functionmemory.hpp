#pragma once
#include <unordered_map>

#include "variable.hpp"


class FunctionMemory
{
public:
	void Add(FuncVariable func_var);
	FuncVariable Get(std::string identifier);
	bool Exist(std::string identifier);
private:
	std::unordered_map<std::string, FuncVariable> func_vars;
};