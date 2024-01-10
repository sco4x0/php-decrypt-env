<?php

require 'vendor/autoload.php';

use PhpParser\Node;
use PhpParser\Node\Stmt;
use PhpParser\Node\Expr;
use PhpParser\NodeVisitorAbstract;

$varCount = 0;
$funcCount = 0;
$maps = [];
$b64func = '';

class VariableVisitor extends NodeVisitorAbstract
{
    public function leaveNode(Node $node) {
        global $varCount;
        global $funcCount;
        global $maps;
        if ($node instanceof Expr\Variable) {
            $varName = is_string($node->name) ? $node->name : $node->name->name;
            $varName = md5($varName);
            if ($varName && !array_key_exists($varName, $maps)) {
                $maps[$varName] = 'var' . $varCount++;
            }
            $node->name = $maps[$varName];
        }
        if ($node instanceof Node\Stmt\Function_) {
            $funcName = $node->name->name;
            $funcName = md5($funcName);
            if ($funcName && !array_key_exists($funcName, $maps)) {
                $maps[$funcName] = 'func' . $funcCount++;
            }
            $node->name = $maps[$funcName];
        }
    }
}

class FuncVisitor extends NodeVisitorAbstract {
    public function leaveNode(Node $node) {
        global $varCount;
        global $funcCount;
        global $maps;
        global $b64func;
        if ($node instanceof Node\Expr\Assign && $node->expr instanceof Node\Scalar\String_) {
            if (array_key_exists(md5($node->expr->value), $maps)) {
                $node->expr->value = $maps[md5($node->expr->value)];
            }
            if ($node->expr->value == 'base64_decode') {
                $b64func = $node->var->name;
            }
        }
    }
}

class AssignVisitor extends NodeVisitorAbstract {
    public function leaveNode(Node $node) {
        global $maps;
        global $b64func;
        if ($node instanceof Node\Expr\Assign && $node->expr instanceof Node\Expr\FuncCall) {
            if ($node->expr->name->name == $b64func) {
                $decode_value = base64_decode($node->expr->args[0]->value->value);
                $node->var->value = $decode_value;
            }
        }
    }
}

$code = file_get_contents('index.php');
$parser = (new PhpParser\ParserFactory)->create(PhpParser\ParserFactory::PREFER_PHP5);
$stmts = $parser->parse($code);

$traverser = new PhpParser\NodeTraverser;
$traverser->addVisitor(new VariableVisitor());
$stmts = $traverser->traverse($stmts);

$traverser = new PhpParser\NodeTraverser;
$traverser->addVisitor(new FuncVisitor());
$stmts = $traverser->traverse($stmts);

file_put_contents('index.ast', print_r($stmts, true));
$prettyPrinter = new PhpParser\PrettyPrinter\Standard;
file_put_contents('index-pretty.php', $prettyPrinter->prettyPrintFile($stmts));