#pragma once
#include <optional>
#include <vector>
#include <iostream>

#include "variable.hpp"
 
class Environment;

class EnvStack
{
public:
	EnvStack();

	std::vector<Environment> envs;
	int last_index = -1;
	int current = last_index;

	std::optional<Environment> Get();
	Environment& GetRef();
	std::pair<Variable, Environment> Get(std::string identifier);
	void Push(Environment env);
	std::optional<Environment> Pop();
	void Add(Variable var);
	void Assign(std::string identifier, std::any value);
	void Reset();
};