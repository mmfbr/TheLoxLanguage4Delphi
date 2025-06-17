#include "compare.hpp"

bool CompareSyntaxTokens(SyntaxToken s1, SyntaxToken s2)
{
	if (s1.get_len() != s2.get_len())
	{
		return false;
	}
	if (s1.get_pos() != s2.get_pos())
	{
		return false;
	}
	if (s1.get_row() != s2.get_row())
	{
		return false;
	}
	if (s1.get_token_t() != s2.get_token_t())
	{
		return false;
	}
	if (s1.get_value() != s2.get_value())
	{
		return false;
	}
	return true;
}
