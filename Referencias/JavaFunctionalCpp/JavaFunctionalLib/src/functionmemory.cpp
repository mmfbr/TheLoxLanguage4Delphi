
#include "functionmemory.hpp"

void FunctionMemory::Add(FuncVariable func_var)
{
	if (this->func_vars.contains(func_var.identifier))
	{
		throw std::invalid_argument("Function identifier '" + func_var.identifier + "' already declared.");
	}
	this->func_vars[func_var.identifier] = std::move(func_var);
}

FuncVariable FunctionMemory::Get(std::string identifier)
{
	if (this->func_vars.contains(identifier))
	{
		return std::move(this->func_vars[identifier]);
	}
	throw std::invalid_argument("Function identifier '" + identifier + "' not declared.");
}

bool FunctionMemory::Exist(std::string identifier)
{
	return this->func_vars.contains(identifier);
}


