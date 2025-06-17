#pragma once
#include <iostream>
#include <string>
#include <unordered_map>
#include <optional>
#include <vector>

#include "nodes/vardeclarationnode.hpp"

class Environment {
public:
	//Environment(Environment&& env) = default;
	//Environment(Environment& env) = delete;

	Environment();

	class EnvrionmentVariable
	{
	public:
		std::optional<Variable> Get(std::string identifier);
		void Set(Variable variable);
		void Assign(std::string identifier, std::any value);
	private:
		std::unordered_map<std::string, Variable> variables;
	};

	EnvrionmentVariable env_var;
};
